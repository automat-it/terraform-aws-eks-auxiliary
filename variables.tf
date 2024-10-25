# AWS
variable "aws_account" {
  type        = string
  description = "The AWS account ID where resources will be provisioned."
}

variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be provisioned."
}

# EKS
variable "cluster_name" {
  type        = string
  description = "The name of the Amazon EKS cluster."
}

variable "cluster_nodepool_name" {
  type        = string
  default     = "system"
  description = "The node pool name in the Amazon EKS cluster where all controllers will be installed."
}

variable "iam_openid_provider" {
  type = object({
    oidc_provider_arn = string
    oidc_provider     = string
  })
  default     = null
  description = "The IAM OIDC provider configuration for the EKS cluster."
}

# VPC
variable "vpc_id" {
  type        = string
  description = "The ID of the Virtual Private Cloud (VPC) where resources will be deployed."
}

# Route53
variable "r53_zone_id" {
  type        = string
  default     = ""
  description = "The ID of the Route 53 hosted zone, if DNS records are managed by Route 53."
}

variable "domain_zone" {
  type        = string
  default     = ""
  description = "The domain zone associated with the Route 53 hosted zone."
}

variable "project_env" {
  type        = string
  default     = ""
  description = "The project environment (e.g., dev, staging, prod)."
}

variable "project_name" {
  type        = string
  default     = ""
  description = "The name of the project."
}

variable "notification_slack_token_secret" {
  type        = string
  default     = ""
  description = "AWS Secret Manager key to store a Slack token for notifications."
}

variable "services" {
  type        = any
  default     = {}
  description = "List of services and their parameters (version, configs, namespaces, etc.)."
}

variable "tags" {
  default     = {}
  type        = any
  description = "Resource tags."
}
