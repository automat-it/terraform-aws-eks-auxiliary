# Terraform Auxiliary Module: Helm Release with AWS IAM Roles and Pod Identities

This Terraform module creates a Helm release and associated resources in an AWS environment, with support for IAM Roles for Service Accounts (IRSA) and EKS Pod Identity (currently in testing, for manifests v1 only).

## Prerequisites

Before using this module, ensure you have:

- An AWS account and appropriate permissions to create IAM roles and policies.
- An EKS cluster set up in your AWS environment.
- Helm installed and configured.


## Usage example

```terraform
module "external-dns" {
  source = "path/to/module"

  name                 = "external-dns"
  repository           = "https://kubernetes-sigs.github.io/external-dns"
  chart                = "external-dns"
  namespace            = "default"
  helm_version         = "external-dns-sa"
  service_account_name = "external-dns-sa"

  iam_role_name   = "external-dns-irsa-role"
  irsa_policy_json     = <<-POLICY
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
    POLICY

  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn

  values = ["values.yaml"]
}
```
