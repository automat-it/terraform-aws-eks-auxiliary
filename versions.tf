terraform {
  required_version = "~> 1.0"

  required_providers {
    aws        = ">= 5.0"
    kubernetes = ">= 2.20"
    helm       = ">= 2.9.0"
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
  }
}
