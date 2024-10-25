# Cluster Autoscaler
locals {
  has_autoscaler = try(var.services.cluster-autoscaler.enabled, false)
  # Helm versions
  cluster_autoscaler_helm_version = try(var.services.cluster-autoscaler.helm_version, "9.37.0")
  # K8s namespace to deploy
  cluster_autoscaler_namespace = try(var.services.cluster-autoscaler.namespace, kubernetes_namespace_v1.general.id)
  # K8S Service Account Name
  cluster_autoscaler_service_account_name = try(var.services.cluster-autoscaler.service_account_name, "autoscaler-sa")
  # Helm ovveride values
  cluster_autoscaler_helm_values = <<EOF
    autoDiscovery:
      clusterName: ${local.lower_cluster_name}
    awsRegion: ${var.aws_region}
    rbac:
      create : true
    %{~if try(var.services.cluster-autoscaler.nodepool, var.cluster_nodepool_name) != ""~}
    nodeSelector:
      pool: ${try(var.services.cluster-autoscaler.nodepool, var.cluster_nodepool_name)}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${try(var.services.cluster-autoscaler.nodepool, var.cluster_nodepool_name)}
        effect: NoSchedule
    %{~endif~}
    rbac:
      serviceAccount:
        create: true
        name: ${local.cluster_autoscaler_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.cluster-autoscaler.irsa_role_arn, "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${local.lower_cluster_name}-cluster-autoscaler-iam-role")}

    EOF
  # AWS IAM IRSA
  cluster_autoscaler_irsa_iam_role_name = "${local.lower_cluster_name}-cluster-autoscaler-iam-role"
  cluster_autoscaler_irsa_policy_json   = <<-EOF
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
          "Resource": "arn:aws:autoscaling:${var.aws_region}:${var.aws_account}:autoScalingGroup:*:autoScalingGroupName/*",
          "Condition": {
            "StringEquals": {
              "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
              "aws:ResourceTag/kubernetes.io/cluster/${local.lower_cluster_name}": "owned"
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
  count                = local.has_autoscaler ? 1 : 0
  name                 = "cluster-autoscaler"
  repository           = "https://kubernetes.github.io/autoscaler"
  chart                = "cluster-autoscaler"
  namespace            = local.cluster_autoscaler_namespace
  helm_version         = local.cluster_autoscaler_helm_version
  service_account_name = local.cluster_autoscaler_service_account_name
  irsa_iam_role_name   = local.cluster_autoscaler_irsa_iam_role_name
  irsa_policy_json     = local.cluster_autoscaler_irsa_policy_json
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.cluster_autoscaler_helm_values,
    try(var.services.cluster-autoscaler.additional_helm_values, "")
  ]

  depends_on = [kubernetes_namespace_v1.general]
}
