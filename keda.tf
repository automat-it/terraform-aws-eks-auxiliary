# KEDA
locals {
  # Helm override values
  keda_helm_values = <<EOF
    %{~if coalesce(var.services.argocd.nodeselector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.argocd.nodeselector~}
      ${key}: ${value}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~endif~}
    rbac:
      create: true
    serviceAccount:
      operator:
        create: true
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
          %{~endif~}
      metricServer:
        create: false
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
          %{~endif~}
      webhooks:
        create: false
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
          %{~endif~}
    prometheus:
      metricServer:
        enabled: true
      operator:
        enabled: false
    EOF
}

################################################################################
# KEDA helm
################################################################################
module "keda" {
  source               = "./modules/helm-chart"
  count                = var.services.keda.enabled ? 1 : 0
  name                 = "keda"
  repository           = "https://kedacore.github.io/charts"
  chart                = "keda"
  namespace            = var.services.keda.namespace
  helm_version         = var.services.keda.helm_version
  service_account_name = var.services.keda.service_account_name
  irsa_iam_role_name   = coalesce(var.services.keda.irsa_iam_role_name, "${var.cluster_name}-keda-iam-role")
  irsa_policy_json     = try(var.services.keda.irsa_iam_policy_json, null)
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.keda_helm_values,
    var.services.keda.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
