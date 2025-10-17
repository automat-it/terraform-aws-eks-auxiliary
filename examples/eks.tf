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
variable "install_session_logger" { type = bool }
variable "cluster_iam_role_name" { type = string }
# Worker
variable "eks_worker_min_size" { type = number }
variable "eks_worker_max_size" { type = number }
variable "eks_worker_desired_size" { type = number }
variable "eks_worker_instance_types" { type = list(string) }
variable "eks_worker_capacity_type" { type = string }
# Networking
variable "vpc_cidr" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "domain_zone" { type = string }
variable "r53_zone_id" { type = string }
# AWS
variable "aws_account_id" { type = string }
variable "aws_region" { type = string }
variable "eks_cluster_name" { type = string }
variable "system_node_group_name" { type = string }
variable "ami_release_version" { type = string }
variable "ami_type" { type = string }
variable "instance_types" { type = list(string) }

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> v21.3.2"

  name                   = var.eks_cluster_name
  kubernetes_version     = "1.34"
  endpoint_public_access = false

  addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        autoScaling = {
          enabled     = true
          minReplicas = 2
          maxReplicas = 10
        }
        tolerations = [
          {
            key      = "dedicated"
            effect   = "NoSchedule"
            operator = "Equal"
            value    = "system"
          }
        ]
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "pool"
                      operator = "In"
                      values   = ["system"]
                    }
                  ]
                }
              ]
            }
          }
        }
      })
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

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids # module.private-subnets.subnets.ids

  ### IAM Role cluser
  iam_role_use_name_prefix = false
  iam_role_name            = var.cluster_iam_role_name
  iam_role_additional_policies = {
    amazon_eks_service_policy = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  }

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_security_group      = true
  create_node_security_group = false

  security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description = "Access from MGMT environment"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }
  authentication_mode = "API"

  access_entries = {
    terraform = {
      principal_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform"
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    onelogin-admin = {
      principal_arn = "arn:aws:iam::${var.aws_account_id}:role/OneLogin-AIT-AdministratorAccess"
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    system = {
      metadata_options = {
        http_put_response_hop_limit = 2
      }
      enable_monitoring = true
      name              = var.system_node_group_name
      use_name_prefix   = false
      #Node Group Settings
      use_latest_ami_release_version        = false
      ami_release_version                   = var.ami_release_version
      ami_type                              = var.ami_type
      instance_types                        = var.instance_types
      attach_cluster_primary_security_group = true

      min_size     = var.eks_system_min_size
      max_size     = var.eks_system_max_size
      desired_size = var.eks_system_desired_size

      instance_types = var.eks_system_instance_types
      labels = {
        pool = "system"
      }

      iam_role_additional_policies = merge(
        {
          AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        var.install_session_logger ? { SessionLoggingPolicy = aws_iam_policy.eks_session_logging_policy[0].arn } : {}
      )

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

      iam_role_additional_policies = merge(
        {
          AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        var.install_session_logger ? { SessionLoggingPolicy = aws_iam_policy.eks_session_logging_policy[0].arn } : {}
      )

      tags = {
        pool = "worker"
      }
    }
  }
}

resource "aws_iam_policy" "eks_session_logging_policy" {
  count = var.install_session_logger ? 1 : 0

  name   = "eks-session-logging-policy"
  policy = data.aws_iam_policy_document.eks-session-logging-policy[0].json
}

# Policy document for SSM SSH session logging
data "aws_iam_policy_document" "eks-session-logging-policy" {
  count = var.install_session_logger ? 1 : 0

  statement {
    sid = "CloudWatchAccessForSessionManager"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "KMSEncryptionForSessionManager"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    resources = [
      module.session-logger[0].kms_key
    ]
  }
  statement {
    sid = "S3BucketAccessForSessionManager"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      module.log-bucket[0].log_bucket.arn,
      "${module.log-bucket[0].log_bucket.arn}/*",
    ]
  }
  statement {
    sid = "S3BucketEncryptionForSessionManager"
    actions = [
      "s3:GetEncryptionConfiguration",
    ]
    resources = [
      module.log-bucket[0].log_bucket.arn
    ]
  }
}

### SG to work with the EKS AKB ingress controller
resource "aws_security_group" "alb-controller-sg" {
  name        = "cluster-alb-controller-sg"
  description = "SG to work with the EKS ALB ingress controller"
  vpc_id      = var.vpc_id
}
