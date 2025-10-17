# External Secrets
locals {
  # Helm override values
  external_secrets_helm_values = <<EOF
    installCRDs: true
    webhook:
      create: false
    certController:
      create: false
    env:
      AWS_REGION: ${var.aws_region}
    serviceAccount:
      create: true
      name: "${var.services.external-secrets.service_account_name}"
      annotations:
        %{~if coalesce(var.services.external-secrets.iam_role_arn, try(module.external-secrets[0].iam_role_arn, "no_annotation")) != "no_annotation"~}
        eks.amazonaws.com/role-arn: ${coalesce(var.services.external-secrets.iam_role_arn, module.external-secrets[0].iam_role_arn)}
        %{~endif~}
    %{~if coalesce(var.services.external-secrets.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.external-secrets.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.external-secrets.node_selector, {}) != {} || coalesce(var.services.external-secrets.additional_tolerations, []) != []~}
    tolerations:
    %{~for key, value in var.services.external-secrets.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~if var.services.external-secrets.additional_tolerations != null~}
    %{~for i in var.services.external-secrets.additional_tolerations~}
      - key: ${i.key}
        operator: ${i.operator}
        value: ${i.value}
        effect: ${i.effect}
        %{~if i.tolerationSeconds != null~}
        tolerationSeconds: ${i.tolerationSeconds}
        %{~endif~}
    %{~endfor~}
    %{~endif~}
    %{~else~}
    tolerations: []
    %{~endif~}
    EOF

  external_secrets_iam_policy_json = <<-POLICY
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

################################################################################
# External secrets helm
################################################################################
module "external-secrets" {
  source               = "./modules/helm-chart"
  count                = var.services.external-secrets.enabled ? 1 : 0
  name                 = var.services.external-secrets.chart_name
  repository           = "https://charts.external-secrets.io"
  chart                = "external-secrets"
  namespace            = var.services.external-secrets.namespace
  helm_version         = var.services.external-secrets.helm_version
  service_account_name = var.services.external-secrets.service_account_name
  iam_role_name        = coalesce(var.services.external-secrets.iam_role_name, "${var.cluster_name}-external-secrets-iam-role")
  iam_policy_json      = coalesce(var.services.external-secrets.iam_policy_json, local.external_secrets_iam_policy_json)
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.external_secrets_helm_values,
    var.services.external-secrets.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
