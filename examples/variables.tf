variable "tfstate_region" {
  type    = string
  default = "ca-central-1"
}
variable "tfstate_bucket" {
  type    = string
  default = "tfstate.ca-central-1.terraform-ci"
}

variable "project_name" {
  description = "Name of CI Project"
  type        = string
  default     = "Terraform-CI"
}
