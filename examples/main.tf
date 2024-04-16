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

# Locals

locals {
  aws_account             = data.aws_caller_identity.current.id
  aws_region              = "ca-central-1"
  project_name            = "Terraform-CI"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_name            = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  iam_openid_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn


  base_tags = {
  }
  # Base resource-independent tags
  provider_base_tags = {
    Project    = local.project_name
    Managed_by = "terraform"
    Name       = ""
  }
}
