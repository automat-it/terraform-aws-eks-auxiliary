### Kubernetes namespaces

# general
resource "kubernetes_namespace_v1" "general" {
  metadata {
    annotations = {
      name = "general"
    }
    name = "general"
  }
}

# security
resource "kubernetes_namespace_v1" "security" {
  metadata {
    annotations = {
      name = "security"
    }
    name = "security"
  }
}

# argocd
resource "kubernetes_namespace_v1" "argocd" {
  count = try(var.services["argocd"]["enabled"], false) ? 1 : 0
  metadata {
    annotations = {
      name = "argocd"
    }
    name = "argocd"
  }
}

### EKS data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}
