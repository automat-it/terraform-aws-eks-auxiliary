resource "helm_release" "this" {
  name              = var.name
  repository        = var.repository
  chart             = var.chart
  namespace         = var.namespace
  create_namespace  = true
  version           = var.helm_version
  dependency_update = var.dependency_update
  force_update      = var.force_update

  values = var.values

  depends_on = [
    kubernetes_service_account.irsa
  ]
}

resource "aws_iam_role_policy" "eks-system-external-dns" {
  count  = var.irsa_policy_json != null ? 1 : 0
  name   = "${var.name}-policy"
  role   = aws_iam_role.irsa[0].id
  policy = var.irsa_policy_json
}

resource "aws_iam_role" "irsa" {
  count              = var.enable_pod_identity != true && var.irsa_iam_role_name != null ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy[0].json
  name               = var.irsa_iam_role_name
}

resource "kubernetes_service_account" "irsa" {
  count = var.irsa_policy_json != null ? 1 : 0
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa[0].arn
    }
  }
}


# EKS Pod Identity template
# Important! Currently works with metadata manifests v1 only

resource "aws_iam_role" "pod_identity" {
  count              = var.enable_pod_identity ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.pod_identity[0].json
  name               = var.irsa_iam_role_name
}

resource "aws_eks_pod_identity_association" "pod_identity" {
  count           = var.enable_pod_identity ? 1 : 0
  cluster_name    = var.eks_cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.pod_identity[0].arn
}

resource "kubernetes_service_account" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }
}
