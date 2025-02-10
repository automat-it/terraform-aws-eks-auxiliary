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

### EKS data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}
