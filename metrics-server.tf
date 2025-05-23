# Metrics server
locals {
  # Helm override values
  metrics_server_helm_values = <<EOF
    %{~if coalesce(var.services.metrics-server.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.metrics-server.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.metrics-server.node_selector, {}) != {} || coalesce(var.services.metrics-server.additional_tolerations, []) != []~}
    tolerations:
    %{~for key, value in var.services.metrics-server.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
        %{~if var.services.keda.additional_tolerations != null~}
    %{~for i in var.services.metrics-server.additional_tolerations~}
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
}

################################################################################
# Metrics server helm
################################################################################
module "metrics-server" {
  source       = "./modules/helm-chart"
  count        = var.services.metrics-server.enabled ? 1 : 0
  name         = var.services.metrics-server.chart_name
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
