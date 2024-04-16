terraform {
  backend "s3" {
    region         = "ca-central-1"
    bucket         = "tfstate.ca-central-1.terraform-ci"
    key            = "environments/terraform-ci/eks-auxiliary/terraform.tfstate"
    dynamodb_table = "tfstate-locks.ca-central-1.terraform-ci"
  }
  required_providers {
    aws = {
      version = "~> 5.40"
      source  = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "aws" {
  region = local.aws_region

  # Default tags to be set for all the resources created by the AWS provider
  default_tags {
    tags = local.provider_base_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.deploy_role]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.deploy_role]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.deploy_role]
  }
}

# Locals

locals {
  aws_account             = data.aws_caller_identity.current.id
  aws_region              = "ca-central-1"
  project_name            = "Terraform-CI"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_name            = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  iam_openid_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  deploy_role       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GitHub_runner_role"


  base_tags = {
  }
  # Base resource-independent tags
  provider_base_tags = {
    Project    = local.project_name
    Managed_by = "terraform"
    Name       = ""
  }
}
