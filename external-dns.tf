# External DNS controller
locals {
  # Helm override values
  external_dns_helm_values = <<EOF
    logLevel: debug
    txtOwnerId: ${var.r53_zone_id}
    extraArgs:
      - --label-filter=external-dns-exclude notin (true)
    domainFilters:
      - ${var.domain_zone}
    %{~if coalesce(var.services.external-dns.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.external-dns.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.external-dns.node_selector, {}) != {} || coalesce(var.services.external-dns.tolerations, []) != []~}
    tolerations:
    %{~for key, value in var.services.external-dns.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~if var.services.external-dns.tolerations != null~}
    %{~for i in var.services.external-dns.tolerations~}
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
    policy: upsert-only
    serviceAccount:
      create: true
      name: ${var.services.external-dns.service_account_name}
      annotations:
        %{~if coalesce(var.services.external-dns.irsa_role_arn, try(module.external-dns[0].irsa_role_arn, "no_annotation")) != "no_annotation"~}
        eks.amazonaws.com/role-arn: ${coalesce(var.services.external-dns.irsa_role_arn, module.external-dns[0].irsa_role_arn)}
        %{~endif~}
    EOF

  # AWS IAM IRSA
  external_dns_irsa_policy_json = <<-POLICY
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

################################################################################
# External DNS controller helm
################################################################################
module "external-dns" {
  source               = "./modules/helm-chart"
  count                = var.services.external-dns.enabled ? 1 : 0
  name                 = "external-dns"
  repository           = "https://kubernetes-sigs.github.io/external-dns"
  chart                = "external-dns"
  namespace            = var.services.external-dns.namespace
  helm_version         = var.services.external-dns.helm_version
  service_account_name = var.services.external-dns.service_account_name
  irsa_iam_role_name   = coalesce(var.services.external-dns.irsa_iam_role_name, "${var.cluster_name}-external-dns-iam-role")
  irsa_policy_json     = coalesce(var.services.external-dns.irsa_iam_policy_json, local.external_dns_irsa_policy_json)
  iam_openid_provider  = var.iam_openid_provider
  values = [
    local.external_dns_helm_values,
    var.services.external-dns.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
