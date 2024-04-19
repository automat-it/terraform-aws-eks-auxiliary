locals {
  # Helm versions
  otl_helm_version = "0.87.0"

  # IAM IRSA roles
  otl_irsa_iam_role_name = "${var.cluster_name}-otl-iam-role"
}

### Cluster Monitoring and alerting with OTL+CloudWatch
module "monitoring" {
  count  = var.has_monitoring && var.monitoring_config != {} ? 1 : 0
  source = "./helm-charts/otl-agent-monitoring"

  eks_cluster_name = var.cluster_name
  aws_region       = var.aws_region

  irsa_iam_role_name      = local.otl_irsa_iam_role_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  helm_version = local.otl_helm_version

  toleration_pool = "system"
  namespace       = "monitoring"

  create_cw_alerts = lookup(var.monitoring_config, "create_alerts", false)

  cw_alert_prefix       = lookup(lookup(var.monitoring_config, "alert_config", {}), "alert_prefix", "EKS-Cluster")
  cw_alert_period       = lookup(lookup(var.monitoring_config, "alert_config", {}), "alert_period", 300)
  cw_evaluation_periods = lookup(lookup(var.monitoring_config, "alert_config", {}), "evaluation_periods", 2)

  cw_alert_notification_sns_arns = lookup(lookup(var.monitoring_config, "alert_config", {}), "notification_sns_arns", [])

  # In additional to the alert metrics per cluster, we could collect the minimal
  # statistic per kubernetes pods and nodes. The
  collect_minimal_statistic = lookup(var.monitoring_config, "collect_minimal_statistic", false)
  # Interval setup. If we put "5m", the metrics resolution could be covered by the AWS Free tire
  # "1m" is the higest resolution here
  k8s_metrics_interval = lookup(var.monitoring_config, "k8s_metrics_interval", "5m")
}


### Kubernetes namespaces

# general
resource "kubernetes_namespace_v1" "general" {
  metadata {
    annotations = {
      name = "general"
    }
    name = "general"
  }
}

# security
resource "kubernetes_namespace_v1" "security" {
  metadata {
    annotations = {
      name = "security"
    }
    name = "security"
  }
}

# argocd
resource "kubernetes_namespace_v1" "argocd" {
  count = var.has_argocd == true ? 1 : 0
  metadata {
    annotations = {
      name = "argocd"
    }
    name = "argocd"
  }
}
