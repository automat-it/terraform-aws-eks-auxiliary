variable "chart_version" { default = "" }
variable "chart_name" { default = "argo-cd" }
variable "namespace" { default = "argocd" }
variable "service_account_name" {
  type = string
}
variable "aws_region" {
  default = "us-east-1"
}
variable "notification_slack_token_secret" {
  type        = string
  description = "AWS Secret manager key to keep a slack token"
}
