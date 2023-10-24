variable "name" {
  type    = string
  default = "datadog"
  description = "Helm release name"
}

variable "namespace" {
  type    = string
  default = "monitoring"
  description = "Have helm_resource create the namespace, default true"
}

variable "create_namespace" {
  type    = bool
  default = true
  description = "Have helm_resource create the namespace, default true"
}

variable "helm_chart_version" {
  type    = string
  default = "3.33.8"
  description = "Version of the Datadog Helm chart to use"
}

variable "helm_chart_name" {
  type    = string
  default = "datadog"
  description = "Helm chart name to be installed"
}

variable "helm_repo_url" {
  type    = string
  default = "https://helm.datadoghq.com"
  description = "Helm repository for datadog chart"
}

variable "dependency_update" {
  type        = bool
  default     = false
  description = "(Optional) Runs helm dependency update before installing the chart. Defaults to false."
}

variable "values" {
  type        = list(any)
  default     = null
  description = "(Optional) List of values in raw yaml to pass to helm. Values will be merged, in order, as Helm does with multiple -f options."
}

variable "datadog_api_key_secret" {
  type        = string
  default     = ""
  description = "Provide the datadog API key to be used with datadog agent pods, default empty string"
}

variable "datadog_app_key_secret" {
  type        = string
  default     = ""
  description = "Provide the datadog APP key to be used with datadog agent pods, default empty string"
}

variable "enable_dd_cluster_agent" {
  type        = string
  default     = "true"
  description = "Flag to enable Datadog Cluster Agent, default true"
}

variable "enable_metrics_provider" {
  type        = string
  default     = "false"
  description = "Flag to enable metrics server provider, default false"
}

variable "datadog_agent_site" {
  type        = string
  default     = "datadoghq.com"
  description = "The datadog endpoint to send metrics to, default datadoghq.com"
}

variable "settings" {
  type        = map(any)
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/DataDog/helm-charts/blob/master/charts/datadog/values.yaml for possible values"
}

variable "sensitive_settings" {
  type        = map(any)
  default     = {}
  description = "Additional sensitive settings which will be passed to the Helm chart values, see https://github.com/DataDog/helm-charts/blob/master/charts/datadog/values.yaml for possible values"
}
