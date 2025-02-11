locals {
  nginx_private_service_account_name = "${var.services.nginx-ingress.ingress_class_name}-private-sa"
  nginx_private_helm_values    = <<EOF
    nameOverride: ${var.services.nginx-ingress.ingress_class_name}-private
    controller:
      replicaCount: 2
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
          service.beta.kubernetes.io/aws-load-balancer-type: "external"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
          service.beta.kubernetes.io/aws-load-balancer-scheme: internal
          service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
          service.beta.kubernetes.io/aws-load-balancer-name: "nginx-private-nlb"
      tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.services.nginx-ingress.nodepool}
        effect: NoSchedule
      config:
        use-proxy-protocol: "true"
        real-ip-header: "proxy_protocol"
        use-forwarded-headers: "true"
      ingressClass: ${var.services.nginx-ingress.ingress_class_name}-private
      ingressClassResource:
        name: ${var.services.nginx-ingress.ingress_class_name}-private
        controllerValue: k8s.io/${var.services.nginx-ingress.ingress_class_name}-private
    serviceAccount:
      name: ${local.nginx_private_service_account_name}
    EOF

  nginx_public_service_account_name = "${var.services.nginx-ingress.ingress_class_name}-public-sa"
  nginx_public_helm_values    = <<EOF
    nameOverride: ${var.services.nginx-ingress.ingress_class_name}-public
    controller:
      replicaCount: 2
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
          service.beta.kubernetes.io/aws-load-balancer-type: "external"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
          service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
          service.beta.kubernetes.io/aws-load-balancer-name: "nginx-public-nlb"
      tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.services.nginx-ingress.nodepool}
        effect: NoSchedule
      config:
        use-proxy-protocol: "true"
        real-ip-header: "proxy_protocol"
        use-forwarded-headers: "true"
      ingressClass: ${var.services.nginx-ingress.ingress_class_name}-public
      ingressClassResource:
        name: ${var.services.nginx-ingress.ingress_class_name}-public
        controllerValue: k8s.io/${var.services.nginx-ingress.ingress_class_name}-public
    serviceAccount:
      name: ${local.nginx_public_service_account_name}
    EOF

  nginx_irsa_policy_json = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeInternetGateways"
          ],
          "Resource": "*"
        }
      ]
    }
    EOF
}

resource "aws_security_group_rule" "allow_http_from_nodes" {
  count       = var.services.nginx-ingress.enabled ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.services.nginx-ingress.node_security_group_id
  source_security_group_id = var.services.nginx-ingress.node_security_group_id
  description              = "Allow HTTP traffic from EKS node security group"
}

module "nginx_private" {
  count                = var.services.nginx-ingress.enabled && var.services.aws-alb-ingress-controller.enabled && var.services.nginx-ingress.create_private_class ? 1 : 0
  source               = "./modules/helm-chart"
  name                 = "nginx-private"
  repository           = "https://kubernetes.github.io/ingress-nginx"
  chart                = "ingress-nginx"
  namespace            = var.services.nginx-ingress.namespace
  helm_version         = var.services.nginx-ingress.helm_version
  service_account_name = local.nginx_private_service_account_name
  irsa_policy_json     = local.nginx_irsa_policy_json
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.nginx_private_helm_values,
    var.services.nginx-ingress.additional_helm_values
  ]

  depends_on = [
    kubernetes_namespace_v1.general,
    module.aws-alb-ingress-controller[0]
  ]
}

module "nginx_public" {
  count                = var.services.nginx-ingress.enabled && var.services.aws-alb-ingress-controller.enabled ? 1 : 0
  source               = "./modules/helm-chart"
  name                 = "nginx-public"
  repository           = "https://kubernetes.github.io/ingress-nginx"
  chart                = "ingress-nginx"
  namespace            = var.services.nginx-ingress.namespace
  helm_version         = var.services.nginx-ingress.helm_version
  service_account_name = local.nginx_public_service_account_name
  irsa_policy_json     = local.nginx_irsa_policy_json
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.nginx_public_helm_values,
    var.services.nginx-ingress.additional_helm_values
  ]

  depends_on = [
    kubernetes_namespace_v1.general,
    module.aws-alb-ingress-controller[0]
  ]
}