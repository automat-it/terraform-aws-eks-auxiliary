# AWS Caller Identity

data "aws_caller_identity" "current" {}

# AWS AZ

data "aws_availability_zones" "available" {}

# EKS details

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "environments/terraform-ci/eks/terraform.tfstate"
  }
}

# VPC details

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "environments/terraform-ci/vpc/terraform.tfstate"
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}
