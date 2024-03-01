data "aws_iam_policy_document" "oidc_assume_role_policy" {
  count = var.enable_pod_identity != true && var.iam_openid_provider_arn != null ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.iam_openid_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    principals {
      identifiers = [var.iam_openid_provider_arn]
      type        = "Federated"
    }
  }
}

# EKS Pod Identity template
# Important! Currently works with metadata manifests v1 only

data "aws_iam_policy_document" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}
