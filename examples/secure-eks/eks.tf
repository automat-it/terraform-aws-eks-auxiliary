### EKS
# Common
variable "eks_ami_type" { type = string }
variable "eks_instance_types" { type = list(string) }
variable "eks_attach_cluster_primary_security_group" { type = bool }

#System
variable "eks_system_min_size" { type = number }
variable "eks_system_max_size" { type = number }
variable "eks_system_desired_size" { type = number }
variable "eks_system_instance_types" { type = list(string) }
#variable "eks_system_capacity_type" { type = string }

# Worker
variable "eks_worker_min_size" { type = number }
variable "eks_worker_max_size" { type = number }
variable "eks_worker_desired_size" { type = number }
variable "eks_worker_instance_types" { type = list(string) }
variable "eks_worker_capacity_type" { type = string }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.deploy_role]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
  registries = [
    {
      url      = "oci://public.ecr.aws"
      username = data.aws_ecrpublic_authorization_token.token.user_name
      password = data.aws_ecrpublic_authorization_token.token.password
    }
  ]
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.deploy_role]
  }
}

data "aws_partition" "current" {}
data "aws_availability_zones" "available" {}
data "aws_eks_cluster_auth" "this" {
  name = local.eks_cluster_name
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}

################################################################################
# GP3 Storage Class
################################################################################

resource "kubernetes_storage_class" "gp3" {

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = true
    }
  }

  storage_provisioner = "ebs.csi.aws.com" # Amazon EBS CSI driver

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"
  depends_on          = [module.eks]
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31.4"

  cluster_name                   = local.eks_cluster_name
  cluster_version                = "1.32"
  cluster_endpoint_public_access = false

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc.id
  subnet_ids               = module.private-subnets.subnets.ids
  control_plane_subnet_ids = module.private-subnets.subnets.ids

  # Consider to hardcode the addons version for the producation environment with "addon_version". See coredns addon below as an example.
  cluster_addons = {
    coredns = {
      most_recent = true
      #     addon_version  = "v1.18.6-eksbuild.1"
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = true
  create_node_security_group    = true

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description = "Access from MGMT environment"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [local.mgmt_vpc_cidr]
    }
  }

  access_entries = {
    onelogin-admin = {
      principal_arn = "arn:aws:iam::${local.aws_account}:role/OneLogin-AIT-AdministratorAccess"
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    },
    # user-admin = {
    #   principal_arn = "arn:aws:iam::${local.aws_account}:user/USER-NAME"
    #   type          = "STANDARD"

    #   policy_associations = {
    #     admin = {
    #       policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = var.eks_ami_type
    instance_types = var.eks_instance_types

    attach_cluster_primary_security_group = var.eks_attach_cluster_primary_security_group
  }

  eks_managed_node_groups = {
    system = {
      min_size     = var.eks_system_min_size
      max_size     = var.eks_system_max_size
      desired_size = var.eks_system_desired_size

      instance_types = var.eks_system_instance_types
      labels = {
        pool = "system"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      }

      tags = {
        pool = "system"
      }
    }
    worker = {
      min_size     = var.eks_worker_min_size
      max_size     = var.eks_worker_max_size
      desired_size = var.eks_worker_desired_size

      instance_types = var.eks_worker_instance_types
      capacity_type  = var.eks_worker_capacity_type
      labels = {
        pool = "worker"
      }

      tags = {
        pool = "worker"
      }
    }
  }
}

### SG to work with the EKS AKB ingress controller
resource "aws_security_group" "alb-controller-sg" {
  name        = "cluster-alb-controller-sg"
  description = "SG to work with the EKS ALB ingress controller"
  vpc_id      = module.vpc.vpc.id
  tags        = local.provider_base_tags
}
