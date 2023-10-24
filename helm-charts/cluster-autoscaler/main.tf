### Variables
variable "aws_account" { type = string }
variable "aws_region" { type = string }
variable "eks_cluster_name" { type = string }
variable "helm_version" { default = "9.18.1" }
variable "namespace" { default = "general" }
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }
variable "irsa_iam_role_name" { type = string }
variable "autoscaler_service_account_name" { 
  type = string 
  default = "autoscaler-sa"
  }
data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.iam_openid_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.autoscaler_service_account_name}"]
    }

    principals {
      identifiers = [var.iam_openid_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "irsa_role" {
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  name               = var.irsa_iam_role_name
}

### Inline IAM Policy: Allow cluster-autoscaler to discover ASGs
resource "aws_iam_role_policy" "eks-system-autoscaler" {
  name = "autoscaler-policy"
  role = aws_iam_role.irsa_role.id

  policy = <<-EOF
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
              "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}": "owned"
            }
          }
        }
      ]
    }
    EOF
}

### Cluster-autoscaler helm
resource "helm_release" "cluster-autoscaler" {
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  namespace        = var.namespace
  create_namespace = true

  version = var.helm_version

  dependency_update = true

  values = [<<EOF
    autoDiscovery:
      clusterName: ${var.eks_cluster_name}
    awsRegion: ${var.aws_region}
    rbac:
      create : true
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    rbac:
      serviceAccount:
        create: true
        name: ${var.autoscaler_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
          
    EOF
  ]
}

# vim:filetype=terraform ts=2 sw=2 et:
