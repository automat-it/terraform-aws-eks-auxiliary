module "secure-eks" {

  source = "git@bitbucket.org:automatitdevops/terraform-aws-ait-eks-auxiliary.git"

  # Components
  has_autoscaler        = true
  has_aws_lb_controller = true
  has_external_dns      = false
  has_metrics_server    = true
  has_external_secrets  = true
  has_monitoring        = true

  # AWS
  aws_account  = local.aws_account
  aws_region   = local.aws_region
  basename     = local.basename

  # EKS
  cluster_name            = module.eks.cluster_name
  iam_openid_provider_url = module.eks.oidc_provider
  iam_openid_provider_arn = module.eks.oidc_provider_arn

  # VPC
  vpc_id = module.vpc.vpc.id

  # Monitoring
  monitoring_config = {
    create_alerts = true
    alert_config = {
      alert_prefix          = "EKS-Cluster"
      alert_period          = 300
      evaluation_periods    = 2
      notification_sns_arns = []
    }
    collect_minimal_statistic = true
    k8s_metrics_interval      = "5m"
  }

#  depends_on = [
#    module.eks,
#    module.vpc,
#    module.private-subnets,
#    module.isolated-subnets,
#    module.public-subnets,
#    module.tgw-attachment,
#    module.tgw-sharing-attachment,
#    module.tgw-peering-attachment,
#    module.tgw-peering,
#    module.tgw
#  ]
}
