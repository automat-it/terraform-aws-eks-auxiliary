### Variables
variable "helm_version" { default = "2.10.2" }
variable "namespace" { default = "general" }
variable "keda_toleration_pool" { default = "master" }

variable "autoscaler_service_account_name" {
  type    = string
  default = "keda-sa"
}
variable "irsa_iam_role_name" { type = string }
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.iam_openid_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.autoscaler_service_account_name}"]
    }

    principals {
      identifiers = [var.iam_openid_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "irsa_role" {
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  name               = var.irsa_iam_role_name
}

### Cluster-autoscaler helm
resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = var.namespace
  create_namespace = true

  version = var.helm_version

  dependency_update = true

  values = [<<EOF
    nodeSelector:
      pool: ${var.keda_toleration_pool}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.keda_toleration_pool}
        effect: NoSchedule
    rbac:
      create: true
    serviceAccount:
      create: true
      name: ${var.autoscaler_service_account_name}
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
    prometheus:
      metricServer:
        enabled: true
      operator:
        enabled: false
    EOF
  ]
}

output "role_id" {
  value = aws_iam_role.irsa_role.id
}
# vim:filetype=terraform ts=2 sw=2 et:
