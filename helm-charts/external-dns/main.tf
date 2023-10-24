### Variables
variable "eks_cluster_name" { type = string }
variable "r53_zone_id" { type = string }
variable "domain_zone" { type = string }
variable "helm_version" { default = "1.9.0" }
variable "namespace" { default = "general" }
variable "external_dns_service_account_name" {
  type    = string
  default = "external-dns-sa"
}
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }
variable "irsa_iam_role_name" { type = string }

variable "dns_policy" {
  type        = string
  description = "Modify how DNS records are synchronized between sources and providers (options: sync, upsert-only)"
  default     = "upsert-only"
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.iam_openid_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.external_dns_service_account_name}"]
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

### Inline IAM Policy: Allow external dns to work
resource "aws_iam_role_policy" "eks-system-external-dns" {
  name = "external-dns-policy"
  role = aws_iam_role.irsa_role.id

  # Retrieved from:
  # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#iam-permissions
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource": [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
    EOF
}

### External-dns helm
resource "helm_release" "external-dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  namespace        = var.namespace
  create_namespace = true

  version = var.helm_version

  dependency_update = true

  values = [<<EOF
    logLevel: debug
    txtOwnerId: ${var.r53_zone_id}
    extraArgs:
      - --label-filter=external-dns-exclude notin (true)
    domainFilters:
      - ${var.domain_zone}
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    policy: ${var.dns_policy}
    serviceAccount:
      create: true
      name: ${var.external_dns_service_account_name}
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
    EOF
  ]
}

# vim:filetype=terraform ts=2 sw=2 et:
