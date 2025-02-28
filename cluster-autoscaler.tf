# Cluster Autoscaler
locals {
  # Helm override values
  cluster_autoscaler_helm_values = <<EOF
    autoDiscovery:
      clusterName: ${var.cluster_name}
    awsRegion: ${var.aws_region}
    rbac:
      create : true
    %{~if coalesce(var.services.cluster-autoscaler.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.cluster-autoscaler.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.cluster-autoscaler.node_selector, {}) != {} || coalesce(var.services.cluster-autoscaler.tolerations, []) != []~}
    tolerations:
    %{~for key, value in var.services.cluster-autoscaler.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~if var.services.aws-alb-ingress-controller.tolerations != null~}
    %{~for i in var.services.aws-alb-ingress-controller.tolerations~}
      - key: ${i.key}
        operator: ${i.operator}
        value: ${i.value}
        effect: ${i.effect}
        %{~if i.tolerationSeconds != null~}
        tolerationSeconds: ${i.tolerationSeconds}
        %{~endif~}
    %{~endfor~}
    %{~endif}
    %{~else~}
    tolerations: []
    %{~endif~}
    rbac:
      serviceAccount:
        create: true
        name: ${try(var.services.cluster-autoscaler.service_account_name, null) != null ? var.services.cluster-autoscaler.service_account_name : ""}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.cluster-autoscaler.irsa_role_arn, null) != null ? var.services.cluster-autoscaler.irsa_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.cluster_name}-cluster-autoscaler-iam-role"}
    EOF

  # AWS IAM IRSA
  cluster_autoscaler_irsa_policy_json = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeTags",
            "autoscaling:DescribeLaunchConfigurations",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:DescribeInstanceTypes"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "autoscaling:BatchDeleteScheduledAction",
            "autoscaling:BatchPutScheduledUpdateGroupAction",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:UpdateAutoScalingGroup",
            "autoscaling:TerminateInstanceInAutoScalingGroup",
            "autoscaling:DeleteScheduledAction",
            "autoscaling:PutScheduledUpdateGroupAction",
            "eks:DescribeNodegroup"
          ],
          "Resource": "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*",
          "Condition": {
            "StringEquals": {
              "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
              "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
            }
          }
        }
      ]
    }
    EOF
}

################################################################################
# Cluster Autoscaler helm
################################################################################
module "cluster-autoscaler" {
  source               = "./modules/helm-chart"
  count                = var.services.cluster-autoscaler.enabled ? 1 : 0
  name                 = "cluster-autoscaler"
  repository           = "https://kubernetes.github.io/autoscaler"
  chart                = "cluster-autoscaler"
  namespace            = var.services.cluster-autoscaler.namespace
  helm_version         = var.services.cluster-autoscaler.helm_version
  service_account_name = var.services.cluster-autoscaler.service_account_name
  irsa_iam_role_name   = coalesce(var.services.cluster-autoscaler.irsa_iam_role_name, "${var.cluster_name}-cluster-autoscaler-iam-role")
  irsa_policy_json     = coalesce(var.services.cluster-autoscaler.irsa_iam_policy_json, local.cluster_autoscaler_irsa_policy_json)
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.cluster_autoscaler_helm_values,
    var.services.cluster-autoscaler.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
