### Kubernetes namespaces

# general
resource "kubernetes_namespace_v1" "general" {
  count = var.create_namespace_general ? 1 : 0
  metadata {
    name = "general"
  }
}

# security
resource "kubernetes_namespace_v1" "security" {
  count = var.create_namespace_security ? 1 : 0
  metadata {
    name = "security"
  }
}

# argocd
resource "kubernetes_namespace_v1" "argocd" {
  count = var.services.argocd.enabled ? 1 : 0
  metadata {
    name = "argocd"
  }
}

### EKS data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}
