variable "tfstate_region" {
  type    = string
  default = "us-east-1"
}
variable "tfstate_bucket" {
  type    = string
  default = "tfstate.us-east-1.terraform-ci"
}

variable "project_name" {
  description = "Name of CI Project"
  type        = string
  default     = "Terraform-CI"
}
