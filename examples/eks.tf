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

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13.1"

  cluster_name                   = var.eks_cluster_name
  cluster_version                = "1.33"
  cluster_endpoint_public_access = false

  cluster_addons = {
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

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = true
  create_node_security_group    = false

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description = "Access from MGMT environment"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # aws-auth
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = false
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.aws_account_id}:role/OneLogin-AIT-AdministratorAccess"
      username = "terraform"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${var.eks_cluster_name}-EKS-Admin-ROLE"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

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
  # tags        = local.base_tags
}
