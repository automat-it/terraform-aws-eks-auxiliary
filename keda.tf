# KEDA
locals {
  # Helm override values
  keda_helm_values = <<EOF
    %{~if coalesce(var.services.keda.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.keda.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.keda.node_selector, {}) != {} || coalesce(var.services.keda.additional_tolerations, []) != []~}
    tolerations:
    %{~for key, value in var.services.keda.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~if var.services.keda.additional_tolerations != null~}
    %{~for i in var.services.keda.additional_tolerations~}
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
    rbac:
      create: true
    serviceAccount:
      operator:
        create: true
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, ""))}
          %{~endif~}
      metricServer:
        create: false
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, ""))}
          %{~endif~}
      webhooks:
        create: false
        name: ${var.services.keda.service_account_name}
        annotations:
          %{~if coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, null), "no_annotation") != "no_annotation"}
          eks.amazonaws.com/role-arn: ${coalesce(var.services.keda.iam_role_arn, try(module.keda[0].iam_role_arn, ""))}
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
  name                 = var.services.keda.chart_name
  repository           = "https://kedacore.github.io/charts"
  chart                = "keda"
  namespace            = var.services.keda.namespace
  helm_version         = var.services.keda.helm_version
  service_account_name = var.services.keda.service_account_name
  iam_role_name        = coalesce(var.services.keda.iam_role_name, "${var.cluster_name}-keda-iam-role")
  iam_policy_json      = try(var.services.keda.iam_policy_json, null)
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.keda_helm_values,
    var.services.keda.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
