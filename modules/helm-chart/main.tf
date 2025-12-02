locals {
  # Important! Currently works with metadata manifests v1 only
  pod_identity_assume_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  oidc_assume_role_policy_json = (
    var.enable_pod_identity == false && var.iam_openid_provider != null && var.service_account_name != null ?
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = ["sts:AssumeRoleWithWebIdentity"]
          Principal = {
            Federated = var.iam_openid_provider.oidc_provider_arn
          }
          Condition = {
            StringEquals = {
              "${var.iam_openid_provider.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            }
          }
        }
      ]
    }) : null
  )
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.repository

  repository_username = var.repository_username
  repository_password = var.repository_password

  chart             = var.chart
  skip_crds         = var.skip_crds
  take_ownership    = var.take_ownership
  upgrade_install   = var.upgrade_install
  namespace         = var.namespace
  create_namespace  = true
  version           = var.helm_version
  dependency_update = var.dependency_update
  force_update      = var.force_update

  values = var.values
}

resource "aws_iam_role_policy" "this" {
  count  = var.iam_policy_json != null && var.create_iam_role ? 1 : 0
  name   = "${var.name}-policy"
  role   = aws_iam_role.this[0].id
  policy = var.iam_policy_json
}

resource "aws_iam_role" "this" {
  count              = !var.enable_pod_identity && var.iam_openid_provider != null && var.create_iam_role ? 1 : 0
  assume_role_policy = local.oidc_assume_role_policy_json
  name               = var.iam_role_name
}

# EKS Pod Identity template
# Important! Currently works with metadata manifests v1 only

resource "aws_iam_role" "pod_identity" {
  count              = var.enable_pod_identity ? 1 : 0
  assume_role_policy = local.pod_identity_assume_role_policy_json
  name               = var.iam_role_name
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
