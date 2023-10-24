module "secure-eks" {

  source = "git@bitbucket.org:automatitdevops/terraform-aws-ait-eks-auxiliary.git?ref=v1.26.10"

  # Components
  has_autoscaler        = true
  has_aws_lb_controller = true
  has_external_dns      = false
  has_metrics_server    = true
  has_external_secrets  = true
  has_argocd            = false
  has_argocd_ingress    = false
  has_keda              = true
  has_monitoring        = true

  # AWS
  aws_account  = local.aws_account
  aws_region   = local.aws_region
  project_env  = var.project_env
  project_name = var.project_name
  basename     = local.basename

  # EKS
  cluster_name            = module.eks.cluster_name
  iam_openid_provider_url = module.eks.oidc_provider
  iam_openid_provider_arn = module.eks.oidc_provider_arn

  # VPC
  vpc_id = module.vpc.vpc.id

  # Route53. Requried for ArgoCD.
  #acm_arn     = module.acm.acm.arn
  #r53_zone_id = data.aws_route53_zone.selected.zone_id
  #domain_zone = local.project_domain

  # ArgoCD
  #argocd_notification_slack_token_secret = "PROD/argocd/slack_token"

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

  # RBAC. Do not define it to allow all nemespaces.
  #namespaces_to_create_allow_groups = ["aaaa", "bbbb"]

  depends_on = [
    module.eks,
    module.vpc,
    module.private-subnets,
    module.isolated-subnets,
    module.public-subnets,
    module.tgw-attachment,
    module.tgw-sharing-attachment,
    module.tgw-peering-attachment,
    module.tgw-peering,
    module.tgw
  ]
}

### AWS ACK APIv2 helm
/*
module "aws-ack-apiv2" {
  source = "../../modules/eks-pub/helm-charts/aws-ack-api"

  aws_region = local.aws_region

  eks_cluster_name = module.eks.cluster_name

  service_account_name    = "${lower(local.basename)}-aws-ack-apiv2-sa"
  iam_openid_provider_url = module.eks.oidc_provider
  iam_openid_provider_arn = module.eks.oidc_provider_arn
}

### ArgoCD SecretsManager access
resource "aws_iam_role_policy" "argocd-secrets-manager" {
  name   = "secrets-manager"
  role   = module.secure-eks.argocd_irsa_role_name
  policy = <<-EOF
   {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "SecretsManager",
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetRandomPassword",
                    "secretsmanager:GetResourcePolicy",
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret",
                    "secretsmanager:ListSecretVersionIds",
                    "secretsmanager:ListSecrets"
                ],
                "Resource": "*"
            }
        ]
    }
   EOF
  depends_on = [
    module.secure-eks
  ]
}
*/
