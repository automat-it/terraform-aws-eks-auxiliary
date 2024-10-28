# Keda
locals {
  has_keda = try(var.services.keda.enabled, false)
  # Helm versions
  keda_helm_version = try(var.services.keda.helm_version, "2.14.3")
  # K8s namespace to deploy
  keda_namespace = try(var.services.keda.namespace, kubernetes_namespace_v1.general.id)
  # K8S Service Account Name
  keda_service_account_name = try(var.services.keda.service_account_name, "keda")
  # AWS IAM IRSA
  keda_irsa_iam_role_name = "${var.cluster_name}-keda-iam-role"
  # Helm ovveride values
  keda_helm_values = <<EOF
    %{~if try(var.services.keda.nodepool, var.cluster_nodepool_name) != ""~}
    nodeSelector:
      pool: ${try(var.services.keda.nodepool, var.cluster_nodepool_name)}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${try(var.services.keda.nodepool, var.cluster_nodepool_name)}
        effect: NoSchedule
    %{~endif~}
    rbac:
      create: true
    serviceAccount:
      operator:
        create: true
        name: ${local.keda_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
      metricServer:
        create: false
        name: ${local.keda_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
      webhooks:
        create: false
        name: ${local.keda_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.keda.irsa_role_arn, try(module.keda[0].irsa_role_arn, ""))}
    prometheus:
      metricServer:
        enabled: true
      operator:
        enabled: false
    EOF
}

################################################################################
# Keda helm
################################################################################
module "keda" {
  source               = "./modules/helm-chart"
  count                = local.has_keda ? 1 : 0
  name                 = "keda"
  repository           = "https://kedacore.github.io/charts"
  chart                = "keda"
  namespace            = local.keda_namespace
  helm_version         = local.keda_helm_version
  service_account_name = local.keda_service_account_name
  irsa_iam_role_name   = local.keda_irsa_iam_role_name
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.keda_helm_values,
    try(var.services.keda.additional_helm_values, "")
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
