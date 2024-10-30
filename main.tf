### Kubernetes namespaces

# general
resource "kubernetes_namespace_v1" "general" {
  metadata {
    name = "general"
  }
}

# security
resource "kubernetes_namespace_v1" "security" {
  metadata {
    name = "security"
  }
}

# argocd
resource "kubernetes_namespace_v1" "argocd" {
  count = try(var.services.argocd.enabled, false) ? 1 : 0
  metadata {
    name = "argocd"
  }
}

### EKS data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

