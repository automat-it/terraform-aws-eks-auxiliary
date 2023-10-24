resource "helm_release" "datadog" {
  name       = var.name
  repository = var.helm_repo_url
  chart      = var.helm_chart_name
  version    = var.helm_chart_version

  namespace         = var.namespace
  create_namespace  = var.create_namespace
  dependency_update = var.dependency_update

  values = var.values

  set_sensitive {
    name  = "datadog.apiKeyExistingSecret"
    value = var.datadog_api_key_secret
  }

  set_sensitive {
    name  = "datadog.appKeyExistingSecret"
    value = var.datadog_app_key_secret
  }

  set {
    name  = "clusterAgent.enabled"
    value = var.enable_dd_cluster_agent
  }

  set {
    name  = "clusterAgent.metricsProvider.enabled"
    value = var.enable_metrics_provider
  }

  set {
    name  = "datadog.site"
    value = var.datadog_agent_site
  }

  dynamic "set" {
    for_each = var.settings
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = var.sensitive_settings
    content {
      name  = set.key
      value = set.value
    }
  }
}