variable "chart_version" { default = "5.12.2" }
variable "chart_name" { default = "argo-cd" }
variable "namespace" { default = "argocd" }
variable "service_account_name" {
  type = string
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