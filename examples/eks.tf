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
  kubernetes {
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
  version = "~> 20.0"

  cluster_name                   = var.eks_cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = false
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations : [{
          key : "dedicated",
          operator : "Equal",
          value : "system",
          effect : "NoSchedule"
        }]
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

  access_entries = {
    # One access entry with a policy associated
    ex-single = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.this["single"].arn

      policy_associations = {
        single = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = toset(["single"])

  name = "Terraform-CI-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "Example"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

### SG to work with the EKS AKB ingress controller
resource "aws_security_group" "alb-controller-sg" {
  name        = "cluster-alb-controller-sg"
  description = "SG to work with the EKS ALB ingress controller"
  vpc_id      = var.vpc_id
  # tags        = local.base_tags
}
