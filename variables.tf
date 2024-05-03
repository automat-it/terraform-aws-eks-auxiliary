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
  description = "The nodepool name in the Amazon EKS cluster to install all the controllers."
}

variable "iam_openid_provider" {
  type = object({
    oidc_provider_arn = string
    oidc_provider     = string
  })
  default = null
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

variable "aws_lb_controller_sg_id" {
  type        = string
  default     = ""
  description = "Explicitly mention the AWS SG ID to work with. If not mentioned, the controller creates the one automatically."
}

variable "has_external_dns" {
  type        = bool
  default     = false
  description = "Whether the External DNS controller will be installed."
}

variable "has_metrics_server" {
  type        = bool
  default     = true
  description = "Whether the External Secrets controller will be installed."
}

variable "has_external_secrets" {
  type        = bool
  default     = false
  description = "Whether the Kubernetes Metrics Server will be installed."
}

variable "has_argocd" {
  type        = bool
  default     = false
  description = "Whether argocd will be installed."
}

variable "argocd_custom_ingress" {
  type    = string
  default = ""
}

variable "has_monitoring" {
  type        = bool
  default     = false
  description = "Whether monitoring components will be installed."
}

variable "monitoring_config" {
  type        = any
  default     = {}
  description = "Configuration map for the monitoring will be installed."
}

variable "has_keda" {
  type        = bool
  default     = false
  description = "Whether keda controller will be installed."
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
  description = "Project environment"
}

variable "project_name" {
  type        = string
  default     = ""
  description = "Project name"
}

### Notifications
variable "notification_slack_token_secret" {
  type        = string
  default     = ""
  description = "AWS Secret manager key to keep a slack token"
}

### Backup ###
variable "enable_backup" {
  type        = bool
  default     = false
  description = "Enable backup for the ArgoCD"
}

variable "backup_cron" {
  type        = string
  default     = "0 1 * * *"
  description = "Backup job run period in crontab format. Default run is daily 1 AM"
}
variable "destination_s3_name" {
  type    = string
  default = ""
}

variable "destination_s3_name_prefix" {
  type    = string
  default = "argocd"
}
