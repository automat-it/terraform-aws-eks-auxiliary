### Variables
variable "eks_cluster_name" {
  type        = string
  description = "AWS EKS cluster name."
}
variable "aws_region" {
  type        = string
  description = "AWS region."
}
variable "helm_version" {
  type        = string
  default     = "0.53.0"
  description = "Helm version for the OpenTelemetry https://github.com/open-telemetry/opentelemetry-helm-charts/releases."
}
variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "Kubernetes namespace name to put the OTL resources to."
}
variable "irsa_iam_role_name" {
  type = string
}
variable "k8s_ns_events_to_collect" {
  type        = string
  default     = "kube-system, general, argocd"
  description = "Comma-separated string of kubernetes namespaces to collect the events from. Put \"all\" to collect all the namespaces"
}
variable "k8s_ns_events_severity" {
  type        = string
  default     = "Warning"
  description = "Kubernetes events severity. Could be: Warning or Normal."
  validation {
    condition     = contains(["Warning", "Normal"], var.k8s_ns_events_severity)
    error_message = "Kubernetes events severity \"Warning\" or \"Normal\"."
  }
}
variable "collect_minimal_statistic" {
  type        = bool
  default     = true
  description = "In additional to the alert metrics per cluster, we are collecting the minimal statistic per kubernetes pods and nodes"
}
### Timing settings
variable "k8s_metrics_interval" {
  type        = string
  default     = "1m"
  description = "Kubernetes metrics scrape inerval in minutes. Could be in seconds as well: 30s"
}
variable "k8s_metrics_batch_interval" {
  type        = string
  default     = "1m"
  description = "Kubernetes metrics scrape batch inerval in minutes. Could be in seconds as well: 30s"
}
variable "cw_alert_period" {
  type        = number
  default     = 60
  description = "AWS CloudWatch Alerts period in seconds."
}
variable "cw_evaluation_periods" {
  type        = number
  default     = 3
  description = "AWS CloudWatch Alerts evaluation period: cw_evaluation_periods * cw_alert_period ==> alert"
}

###
variable "k8s_ns_events_retention_days" {
  type        = number
  default     = 14
  description = "AWS CloudWatch log group retention in days."
}
variable "toleration_pool" {
  type        = string
  default     = "system"
  description = "EKS pool, the current resources are tollerated to."
}
variable "service_account_name" {
  type        = string
  default     = "aws-otel-sa"
  description = "Kubernetes service account name."
}
variable "iam_openid_provider_url" {
  type        = string
  description = "AWS IAM OpenID identity provider url to formate the proper IAM role trust."
}
variable "iam_openid_provider_arn" {
  type        = string
  description = "AWS IAM OpenID identity provider arn to formate the proper IAM role trust."
}

variable "create_cw_alerts" {
  type        = bool
  default     = true
  description = "If we need to create an AWS CloudWatch Alerts setup."
}
variable "cw_alert_prefix" {
  type        = string
  default     = "EKS-Cluster"
  description = "AWS CloudWatch Alerts name prefix."
}
variable "cw_alert_notification_sns_arns" {
  type        = list(string)
  default     = []
  description = "List of the AWS SNS arns to send alert notifications to."
}
