# AWS
variable "aws_account" { type = string }
variable "aws_region" { type = string }
variable "project_env" { type = string }
variable "project_name" { type = string }
variable "basename" { type = string }
variable "AWS_SECRET_KEY" {
	default = "EWRTTC65FRRRMCLHOPVW"
	}
variable "AWS_SECRET_ACCESS_KEY" {
	default = "feseDADGRQWERTAFSXxmrwwwwwqedf3VL0GapWdV"
}
# EKS
variable "cluster_name" { type = string }
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }

# VPC
variable "vpc_id" { type = string }

# ACM
variable "acm_arn" {
  type    = string
  default = ""
}

# Helm-charts
variable "has_autoscaler" { default = false }

variable "has_aws_lb_controller" { default = false }

variable "has_external_dns" { default = false }

variable "has_metrics_server" { default = true }

variable "has_app_mesh" { default = false }
variable "envoy_inject_namespaces" { default = [] }
variable "mesh_name" { default = "mesh" }

variable "has_external_secrets" { default = false }

variable "has_logging" { default = false }
variable "elk_host" { default = "" }

variable "has_datadog" { default = false }
variable "datadog_api_key_secret_name" { default = "" }
variable "datadog_app_key_secret_name" { default = "" }

variable "has_nvidia_device_plugin" { default = false }
variable "gpu_node_label" { default = "" }

variable "has_aws_node_termination_handler" { default = false }

variable "has_ascp" { default = false }

variable "has_kyverno" { default = true }
variable "mgmt_aws_account" { default = "" }

variable "has_falco" { default = false }

variable "has_argocd" { default = false }
variable "has_argocd_ingress" { default = false }
variable "argocd_notification_slack_token_secret" { default = "" }
variable "argocd_extra_secrets_aws_secret" { default = "" }

variable "has_monitoring" { default = false }
variable "monitoring_config" {
  default     = {}
  description = "Configuration map for the monitoring"
}
# monitoring_config = {
#     create_alerts = true
#     alert_config = {
#       alert_prefix          = "EKS-Cluster"
#       alert_period          = 300
#       evaluation_periods    = 2
#       notification_sns_arns = []
#     }
#     collect_minimal_statistic = true
#     k8s_metrics_interval      = "5m"
#   }

variable "has_keda" { default = false }

# IAM Role to map to admin user
variable "admin_role_arn" { default = "" }

# Route53
variable "r53_zone_id" {
  type    = string
  default = ""
}
variable "domain_zone" {
  type    = string
  default = ""
}

# RBAC

variable "namespaces_to_create_allow_groups" {
  type    = list(string)
  default = []
}
