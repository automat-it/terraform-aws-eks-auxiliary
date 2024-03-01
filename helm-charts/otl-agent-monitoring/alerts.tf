locals {
  alert_prefix = "${var.cw_alert_prefix}-${var.eks_cluster_name}"
}

### Create CW alerts
# For 3 minutes crossing we have to obtain an alert:
## cluster_failed_node_count max | Cluster > 0 && missing data
## node_cpu_utilization max | Cluster > 90
## node_memory_utilization max | Cluster > 90
## node_filesystem_utilization max | Cluster >90
## pod_number_of_running_containers min | Cluster < 1
## number_of_container_restarts anomaly | Cluster > 10
#? number_of_container_restarts max | ns kube-system OR ns general > 1
## number_of_warning_events | ns kube-system OR ns general > 1

resource "aws_cloudwatch_metric_alarm" "cluster_failed_node_count" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-cluster-failed-node-count"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = "cluster_failed_node_count"
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "Maximum"
  threshold                 = 0
  alarm_description         = "This metric monitors failed EKS Nodes in the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns

  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_cpu_utilization" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-node-cpu-utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = "node_cpu_utilization"
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "Maximum"
  threshold                 = 90
  alarm_description         = "This metric monitors maximum CPU node utilisation in the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns
  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_memory_utilization" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-node-memory-utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = "node_memory_utilization"
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "Maximum"
  threshold                 = 90
  alarm_description         = "This metric monitors maximum Memory node utilisation in the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns
  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_filesystem_utilization" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-node-filesystem-utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = "node_filesystem_utilization"
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "Maximum"
  threshold                 = 90
  alarm_description         = "This metric monitors maximum Diskspace node utilisation in the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns
  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "pod_number_of_running_containers" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-pod-number-of-running-containers"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = "pod_number_of_running_containers"
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "Minimum"
  threshold                 = 1
  alarm_description         = "This metric monitors minimum containers that running in pods inside the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns
  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "number_of_container_restarts" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-number-of-container-restarts"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  alarm_description         = "This metric monitors maximum for containers restarts in the ${var.eks_cluster_name} cluster"
  insufficient_data_actions = []
  treat_missing_data        = "breaching"

  alarm_actions = var.cw_alert_notification_sns_arns

  threshold_metric_id = "ad1"

  metric_query {
    id = "m1"
    #period      = 0
    return_data = true

    metric {
      dimensions = {
        ClusterName = var.eks_cluster_name
      }
      metric_name = "number_of_container_restarts"
      namespace   = "ContainerInsights"
      period      = var.cw_alert_period
      stat        = "Maximum"
    }
  }
  metric_query {
    expression = "ANOMALY_DETECTION_BAND(m1, 2)"
    id         = "ad1"
    label      = "number_of_container_restarts (expected)"
    #period      = 0
    return_data = true
  }
}

### Scraping logs from logroup

resource "aws_cloudwatch_metric_alarm" "number_of_warning_events" {
  count = var.create_cw_alerts ? 1 : 0

  alarm_name                = "${local.alert_prefix}-number-of-warning-events"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.cw_evaluation_periods
  metric_name               = local.eks_event_metric_name
  namespace                 = "ContainerInsights"
  period                    = var.cw_alert_period
  statistic                 = "SampleCount"
  threshold                 = 1
  alarm_description         = "This metric monitors kubernetes events from ${var.k8s_ns_events_to_collect} namespaces with ${var.k8s_ns_events_severity} severity"
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  alarm_actions = var.cw_alert_notification_sns_arns
}
