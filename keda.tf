# Keda
locals {
  # Helm versions
  keda_helm_version = "2.13.2"
  # K8s namespace to deploy
  keda_namespace = kubernetes_namespace_v1.general.id
  # K8S Service Account Name
  keda_service_account_name = "keda-sa"
  keda_toleration_pool = "system"
  # Helm ovveride values
  keda_helm_values = [<<EOF
    nodeSelector:
      pool: ${local.keda_toleration_pool}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${local.keda_toleration_pool}
        effect: NoSchedule
    rbac:
      create: true
    serviceAccount:
      create: true
      name: ${local.keda_service_account_name}
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
    prometheus:
      metricServer:
        enabled: true
      operator:
        enabled: false
    EOF
  ]
  # AWS IAM IRSA
  keda_irsa_iam_role_name = "${var.cluster_name}-keda-iam-role"
}

module "keda" {
  source                  = "./modules/helm-chart"
  count                   = var.has_keda ? 1 : 0
  name                    = "keda"
  repository              = "https://kedacore.github.io/charts"
  chart                   = "keda"
  namespace               = local.keda_namespace
  helm_version            = local.keda_helm_version
  service_account_name    = local.keda_service_account_name
  irsa_iam_role_name      = local.keda_irsa_iam_role_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  values                  = local.keda_helm_values

  depends_on = [kubernetes_namespace_v1.general]
}
