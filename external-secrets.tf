# External Secrets
locals {
  # Helm versions
  external_secrets_helm_version = "0.9.14"
  # K8s namespace to deploy
  external_secrets_namespace = kubernetes_namespace_v1.general.id
  # K8S Service Account Name
  external_secrets_service_account_name = "external-secrets-sa"
  # Helm ovveride values
  external_secrets_helm_values = [<<EOF
    installCRDs: true
    webhook:
      create: false
    certController:
      create: false
    env:
      AWS_REGION: ${var.aws_region}
    serviceAccount:
      create: true
      name: "${local.external_secrets_service_account_name}"
      annotations:
        eks.amazonaws.com/role-arn: ${try(module.external-secrets[0].irsa_role_arn, "")}
    nodeSelector:
      pool: ${var.cluster_nodepool_name}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.cluster_nodepool_name}
        effect: NoSchedule
    EOF
  ]
  # AWS IAM IRSA
  external_secrets_irsa_iam_role_name = "${var.cluster_name}-external-secrets-iam-role"
  external_secrets_irsa_policy_json   = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "secretsmanager:GetResourcePolicy",
                  "secretsmanager:GetSecretValue",
                  "secretsmanager:DescribeSecret",
                  "secretsmanager:ListSecretVersionIds"
              ],
              "Effect": "Allow",
              "Resource": "*"
          }
      ]
    }
  POLICY
}

module "external-secrets" {
  source                  = "./modules/helm-chart"
  count                   = var.has_external_secrets ? 1 : 0
  name                    = "external-secrets"
  repository              = "https://charts.external-secrets.io"
  chart                   = "external-secrets"
  namespace               = local.external_secrets_namespace
  helm_version            = local.external_secrets_helm_version
  service_account_name    = local.external_secrets_service_account_name
  irsa_iam_role_name      = local.external_secrets_irsa_iam_role_name
  irsa_policy_json        = local.external_secrets_irsa_policy_json
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  values                  = local.external_secrets_helm_values

  depends_on = [kubernetes_namespace_v1.general]
}
