# Metrics server
locals {
  # Helm override values
  metrics_server_helm_values = <<EOF
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
    EOF
}

################################################################################
# Metrics server helm
################################################################################
module "metrics-server" {
  source       = "./modules/helm-chart"
  count        = var.services.metrics-server.enabled ? 1 : 0
  name         = "metrics-server"
  repository   = "https://kubernetes-sigs.github.io/metrics-server"
  chart        = "metrics-server"
  namespace    = var.services.metrics-server.namespace
  helm_version = var.services.metrics-server.helm_version

  values = [
    local.metrics_server_helm_values,
    var.services.metrics-server.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
