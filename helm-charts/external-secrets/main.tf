### Variables
variable "aws_region" { type = string }
variable "eks_cluster_name" { type = string }
variable "helm_version" { default = "0.8.1" }
variable "namespace" { default = "general" }
variable "external_secrets_service_account_name" { 
  type = string
  default = "external-secrets-sa" 
}
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }
variable "irsa_iam_role_name" { type = string }

### IRSA
data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.iam_openid_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.external_secrets_service_account_name}"]
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
### External secret helm
# https://external-secrets.io/v0.5.3/
resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = var.namespace
  create_namespace = true

  version = var.helm_version

  dependency_update = true

  values = [<<EOF
    installCRDs: true
    webhook:
      create: false
    certController:
      create: false
    env:
      AWS_REGION: ${var.aws_region}
    serviceAccount:
      create: true
      name: "${var.external_secrets_service_account_name}"
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    EOF
  ]
}

output "role_arn" {
  value = aws_iam_role.irsa_role.arn
}

output "role_id" {
  value = aws_iam_role.irsa_role.id
}

# vim:filetype=terraform ts=2 sw=2 et:
