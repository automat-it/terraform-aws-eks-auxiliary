# Reloader
locals {
  # Helm override values
  reloader_helm_values = <<EOF
    reloader:
      %{~if coalesce(var.services.reloader.node_selector, {}) != {} || coalesce(var.services.reloader.additional_tolerations, []) != []~}
      deployment:
        %{~if coalesce(var.services.reloader.node_selector, {}) != {} ~}
        nodeSelector:
        %{~for key, value in var.services.reloader.node_selector~}
          ${key}: ${value}
        %{~endfor~}
        %{~endif~}
        tolerations:
        %{~for key, value in coalesce(var.services.reloader.node_selector, {})~}
          - key: dedicated
            operator: Equal
            value: ${value}
            effect: NoSchedule
        %{~endfor~}
        %{~if var.services.reloader.additional_tolerations != null~}
        %{~for i in var.services.reloader.additional_tolerations~}
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
      deployment:
        tolerations: []
      %{~endif~}
    EOF
}

################################################################################
# Reloader helm
################################################################################
module "reloader" {
  source       = "./modules/helm-chart"
  count        = var.services.reloader.enabled ? 1 : 0
  name         = var.services.reloader.chart_name
  repository   = "https://stakater.github.io/stakater-charts"
  chart        = "reloader"
  namespace    = var.services.reloader.namespace
  helm_version = var.services.reloader.helm_version

  values = [
    local.reloader_helm_values,
    var.services.reloader.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
