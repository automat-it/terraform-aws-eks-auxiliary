# External Secrets
locals {
  # Helm versions
  metrics_server_helm_version = "3.12.1"
  # K8s namespace to deploy
  metrics_server_namespace = kubernetes_namespace_v1.general.id
  # Helm ovveride values
  metrics_server_helm_values = [<<EOF
    nodeSelector:
      pool: ${var.cluster_nodepool_name}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.cluster_nodepool_name}
        effect: NoSchedule
    EOF
  ]
}

module "metrics-server" {
  source       = "./modules/helm-chart"
  count        = var.has_metrics_server ? 1 : 0
  name         = "metrics-server"
  repository   = "https://kubernetes-sigs.github.io/metrics-server"
  chart        = "metrics-server"
  namespace    = local.metrics_server_namespace
  helm_version = local.metrics_server_helm_version
  values       = local.metrics_server_helm_values

  depends_on = [kubernetes_namespace_v1.general]
}
