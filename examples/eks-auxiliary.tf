module "secure-eks" {

  source = "git@github.com:automat-it/terraform-aws-eks-auxiliary.git"

  # Components
  has_autoscaler            = true
  has_aws_lb_controller     = true
  has_external_dns          = false
  has_metrics_server        = true
  has_external_secrets      = true
  has_monitoring            = true
  has_argocd                = true
  has_custom_argocd_ingress = false

  # AWS
  aws_account = local.aws_account
  aws_region  = local.aws_region
  basename    = local.basename

  # EKS
  cluster_name            = module.eks.cluster_name
  iam_openid_provider_url = module.eks.oidc_provider
  iam_openid_provider_arn = module.eks.oidc_provider_arn

  # VPC
  vpc_id = module.vpc.vpc.id

  # DNS
  r53_zone_id = aws_route53_zone.route53-domain.zone_id
  domain_zone = aws_route53_zone.route53-domain.name

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

  # Tagging
  project_env  = "test"
  project_name = "eks_aux"

  # Argocd 
  # argocd_ingress = <<EOF
  # enabled: true
  # hosts:
  #   - "argocd.${var.domain_zone}"
  # rules:
  #   - https:
  #       paths:
  #         - backend:
  #             serviceName: ssl-redirect
  #             servicePort: use-annotation
  # annotations:
  #   kubernetes.io/ingress.class: alb
  #   alb.ingress.kubernetes.io/load-balancer-name: "${lower(var.basename)}-argocd-alb"
  #   alb.ingress.kubernetes.io/group.name: "internal"
  #   alb.ingress.kubernetes.io/ip-address-type: ipv4
  #   alb.ingress.kubernetes.io/scheme: "internal"
  #   alb.ingress.kubernetes.io/target-type: ip
  #   alb.ingress.kubernetes.io/healthcheck-port: traffic-port
  #   alb.ingress.kubernetes.io/healthcheck-path: /
  #   alb.ingress.kubernetes.io/success-codes: 200-399
  #   alb.ingress.kubernetes.io/backend-protocol: HTTPS
  #   alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  #   alb.ingress.kubernetes.io/tags: 'Environment=${var.project_env}, Managed_by=helm, Project=${var.project_name}'
  #   alb.ingress.kubernetes.io/ssl-redirect: '443'
  # EOF

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
