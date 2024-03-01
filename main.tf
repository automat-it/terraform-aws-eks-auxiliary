### Versioning
locals {
  # Helm versions
  autoscaler_helm_version        = "9.18.1"
  argocd_helm_version            = "5.28.1"
  metrics_server_helm_version    = "3.8.2"
  aws_lb_controller_helm_version = "1.4.1"
  external_secrets_helm_version  = "0.8.1"
  external_dns_helm_version      = "1.9.0"
  keda_helm_version              = "2.10.2"
  otl_helm_version               = "0.53.0"
  fluentbit_helm_version         = "0.1.27"

  # IAM IRSA roles
  autoscaler_irsa_iam_role_name       = "${var.cluster_name}-autoscaler-iam-role"
  alb_irsa_iam_role_name              = "${var.cluster_name}-alb-iam-role"
  external_secrets_irsa_iam_role_name = "${var.cluster_name}-external-secrets-iam-role"
  external_dns_irsa_iam_role_name     = "${var.cluster_name}-external-dns-iam-role"
  argocd_irsa_iam_role_name           = "${var.cluster_name}-argocd-iam-role"
  keda_irsa_iam_role_name             = "${var.cluster_name}-keda-iam-role"
  otl_irsa_iam_role_name              = "${var.cluster_name}-otl-iam-role"
}

# Please note aws-auth CM was updated by EKS TF module. Now just need to create it on IAM.
resource "aws_iam_role" "eks-admin" {
  name = "${var.basename}-EKS-Admin-ROLE"

  # Allow EC2 instances and users to assume the role
  assume_role_policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "sts:AssumeRole",
          "Principal": {"Service": "ec2.amazonaws.com"}
        },
        {
          "Effect": "Allow",
          "Action": "sts:AssumeRole",
          "Principal": {"AWS": "arn:aws:iam::${var.aws_account}:root"}
        }
      ]
    }
    POLICY
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

### Autoscaler
module "cluster-autoscaler" {
  count  = var.has_autoscaler ? 1 : 0
  source = "./helm-charts/cluster-autoscaler"

  aws_account = var.aws_account
  aws_region  = var.aws_region

  helm_version = local.autoscaler_helm_version

  eks_cluster_name        = var.cluster_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  irsa_iam_role_name = local.autoscaler_irsa_iam_role_name

  depends_on = [kubernetes_namespace_v1.general]
}
### Metricserver
module "metrics-server" {
  count  = var.has_metrics_server ? 1 : 0
  source = "./helm-charts/metrics-server"

  helm_version = local.metrics_server_helm_version

  depends_on = [kubernetes_namespace_v1.general]
}
### AWS LoadBalancer controller
module "aws-load-balancer-controller" {
  count  = var.has_aws_lb_controller ? 1 : 0
  source = "./helm-charts/aws-load-balancer-controller"

  helm_version = local.aws_lb_controller_helm_version

  eks_cluster_name        = var.cluster_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  vpcId                   = var.vpc_id

  irsa_iam_role_name = local.alb_irsa_iam_role_name

  depends_on = [kubernetes_namespace_v1.general]
}
### AWS External Secrets
module "external-secrets" {
  count  = var.has_external_secrets ? 1 : 0
  source = "./helm-charts/external-secrets"

  helm_version = local.external_secrets_helm_version

  eks_cluster_name        = var.cluster_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  aws_region              = var.aws_region

  irsa_iam_role_name = local.external_secrets_irsa_iam_role_name

  depends_on = [kubernetes_namespace_v1.general]
}
### External DNS
module "external-dns" {
  count  = var.has_external_dns ? 1 : 0
  source = "./helm-charts/external-dns"

  r53_zone_id = var.r53_zone_id
  domain_zone = var.domain_zone

  helm_version = local.external_dns_helm_version

  eks_cluster_name        = var.cluster_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  irsa_iam_role_name = local.external_dns_irsa_iam_role_name

  depends_on = [kubernetes_namespace_v1.general]
}
## ArgoCD
module "argocd" {
  count = var.has_argocd ? 1 : 0

  source = "./helm-charts/argocd"

  domain_zone = var.domain_zone

  aws_region = var.aws_region

  irsa_iam_role_name      = local.argocd_irsa_iam_role_name
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  chart_version = local.argocd_helm_version

  notification_slack_token_secret = var.argocd_notification_slack_token_secret
  extra_secrets_aws_secret        = var.argocd_extra_secrets_aws_secret

  enable_backup = false
  #   destination_s3_name        = module.s3-argocd.id
  #   destination_s3_name_prefix = "argocd-backups"

  ingress = <<EOF
  enabled: ${var.has_argocd_ingress}
  hosts:
    - "argocd.${var.domain_zone}"
  rules:
    - https:
        paths:
          - backend:
              serviceName: ssl-redirect
              servicePort: use-annotation
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: "${lower(var.basename)}-argocd-alb"
    alb.ingress.kubernetes.io/group.name: "internal"
    alb.ingress.kubernetes.io/ip-address-type: ipv4
    alb.ingress.kubernetes.io/scheme: "internal"
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: "${var.acm_arn}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/tags: 'Environment=${var.project_env}, Managed_by=helm, Project=${var.project_name}'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  EOF

}

### Keda scaler
module "keda" {
  count = var.has_keda ? 1 : 0

  source = "./helm-charts/keda"

  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  helm_version = local.keda_helm_version

  irsa_iam_role_name = local.keda_irsa_iam_role_name

  keda_toleration_pool = "system"
  namespace            = "general"

  depends_on = [kubernetes_namespace_v1.general]
}

### FluentBit
module "fluentbit" {
  count        = var.has_logging ? 1 : 0
  source       = "./helm-charts/fluentbit"
  helm_version = local.fluentbit_helm_version
  elk_host     = var.elk_host
  elk_region   = var.aws_region
}

### DataDog
module "datadog" {
  count                  = var.has_datadog ? 1 : 0
  source                 = "./helm-charts/datadog"
  datadog_api_key_secret = var.datadog_api_key_secret_name
  datadog_app_key_secret = var.datadog_app_key_secret_name
  settings = {
    // Add tolerations for all taints example
    "agents.tolerations[0].effect"   = "NoSchedule"
    "agents.tolerations[0].operator" = "Exists"
    // Increase rolling update maxUnavailable example
    "agents.updateStrategy.rollingUpdate.maxUnavailable" = "30%"
  }
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

data "kubernetes_all_namespaces" "allns" {}

### Namespace RBAC
# Put to mentioned ns the proper RBAC resources to allow the access
module "rbac" {
  source = "./modules/ns-rbac-resources"

  for_each = toset(var.namespaces_to_create_allow_groups != [] ? var.namespaces_to_create_allow_groups : data.kubernetes_all_namespaces.allns.namespaces)

  namespace = each.value

}
