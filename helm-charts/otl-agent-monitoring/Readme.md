Module example

```
module "otl" {
  source = "../../modules/eks/helm-charts/otl-agent-monitoring"

  eks_cluster_name = module.eks.id
  aws_region       = var.aws_region

  iam_openid_provider_url = module.eks.openid_provider_url
  iam_openid_provider_arn = module.eks.openid_provider_arn

  toleration_pool = "system"
  namespace       = "monitoring"

  create_cw_alerts = true

  cw_alert_prefix       = "EKS-Cluster"
  cw_alert_period       = 300
  cw_evaluation_periods = 2

  # cw_alert_notification_sns_arns = [
  #   "arn:aws:sns:eu-central-1:448454991037:test"
  # ]

  # In additional to the alert metrics per cluster, we could collect the minimal
  # statistic per kubernetes pods and nodes. The 
  collect_minimal_statistic = false
  # Interval setup. If we put "5m", the metrics resolution could be covered by the AWS Free tire
  # "1m" is the higest resolution here 
  k8s_metrics_interval   = "5m"


  depends_on = [module.eks-system]
}
```
