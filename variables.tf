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

# Helm-charts
variable "has_autoscaler" {
  type        = bool
  default     = false
  description = "Whether the cluster autoscaler will be installed."
}

variable "has_aws_lb_controller" {
  type        = bool
  default     = false
  description = "Whether the AWS Load Balancer Controller will be installed."
}

variable "has_external_dns" {
  type        = bool
  default     = false
  description = "Whether the External DNS controller will be installed."
}

variable "has_metrics_server" {
  type        = bool
  default     = true
  description = "Whether the Kubernetes Metrics Server will be installed."
}

variable "has_external_secrets" {
  type        = bool
  default     = false
  description = "Whether the External Secrets controller will be installed."
}

variable "has_argocd" {
  type        = bool
  default     = false
  description = "Whether ArgoCD will be installed."
}

variable "has_karpenter" {
  type        = bool
  default     = false
  description = "Whether Karpenter will be installed."
}

variable "argocd_custom_ingress" {
  type        = string
  default     = ""
  description = "Custom ingress settings for ArgoCD."
}

variable "has_keda" {
  type        = bool
  default     = false
  description = "Whether KEDA (Kubernetes Event-driven Autoscaling) controller will be installed."
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

# Backup
variable "enable_backup" {
  type        = bool
  default     = false
  description = "Enable backup for ArgoCD."
}

variable "backup_cron" {
  type        = string
  default     = "0 1 * * *"
  description = "Backup job schedule in crontab format. The default is daily at 1 AM."
}

variable "destination_s3_name" {
  type        = string
  default     = ""
  description = "The name of the destination S3 bucket for backups."
}

variable "destination_s3_name_prefix" {
  type        = string
  default     = "argocd"
  description = "The prefix for the S3 bucket destination for backups."
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
