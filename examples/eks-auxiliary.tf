module "eks-aux" {

  source = "git@github.com:automat-it/terraform-aws-eks-auxiliary.git"

  project_env  = "test"
  project_name = "eks-aux"

  # Components
  has_autoscaler          = true
  has_aws_lb_controller   = true
  aws_lb_controller_sg_id = aws_security_group.alb-controller-sg.id
  has_external_dns        = true
  has_metrics_server      = true
  has_external_secrets    = true
  has_monitoring          = true
  has_argocd              = true

  # AWS
  aws_account = var.aws_account_id
  aws_region  = var.aws_region

  # EKS
  cluster_name        = module.eks.cluster_name
  iam_openid_provider = module.eks

  # VPC
  vpc_id = var.vpc_id

  # DNS
  domain_zone = var.domain_zone #aws_route53_zone.route53-domain.name

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

  depends_on = [
    module.eks
  ]
}
