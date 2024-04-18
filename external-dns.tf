# External DNS controller
locals {
  # Helm versions
  external_dns_helm_version = "1.14.4"
  # K8s namespace to deploy
  external_dns_namespace = kubernetes_namespace_v1.general.id
  # K8S Service Account Name
  external_dns_service_account_name = "external-dns-sa"
  # Helm ovveride values
  external_dns_helm_values = [<<EOF
    logLevel: debug
    txtOwnerId: ${var.r53_zone_id}
    extraArgs:
      - --label-filter=external-dns-exclude notin (true)
    domainFilters:
      - ${var.domain_zone}
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    policy: upsert-only
    serviceAccount:
      create: true
      name: ${local.external_dns_service_account_name}
      annotations:
        eks.amazonaws.com/role-arn: ${try(module.external-dns[0].irsa_role_arn, "")}
    EOF
  ]
  # AWS IAM IRSA
  external_dns_irsa_iam_role_name = "${var.cluster_name}-external-dns-iam-role"
  external_dns_irsa_policy_json   = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource": [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
    POLICY
}

module "external-dns" {
  source                  = "./modules/helm-chart"
  count                   = var.has_external_dns ? 1 : 0
  name                    = "external-dns"
  repository              = "https://kubernetes-sigs.github.io/external-dns"
  chart                   = "external-dns"
  namespace               = local.external_dns_namespace
  helm_version            = local.external_dns_helm_version
  service_account_name    = local.external_dns_service_account_name
  irsa_iam_role_name      = local.external_dns_irsa_iam_role_name
  irsa_policy_json        = local.external_dns_irsa_policy_json
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  values                  = local.external_dns_helm_values

  depends_on = [kubernetes_namespace_v1.general]
}
