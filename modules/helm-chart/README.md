<!-- BEGIN_TF_DOCS -->
# Terraform Auxiliary Module: Helm Release with AWS IRSA

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

  irsa_iam_role_name   = "external-dns-irsa-role"
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

## Resources

| Name | Type |
|------|------|
| [aws_eks_pod_identity_association.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_role.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eks-system-external-dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.irsa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.pod_identity](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [aws_iam_policy_document.oidc_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chart | Helm chart name. | `string` | n/a | yes |
| helm_version | Helm chart version. | `string` | n/a | yes |
| name | Name of the Helm release. | `string` | n/a | yes |
| repository | Helm chart repository. | `string` | n/a | yes |
| dependency_update | Whether to update dependencies. | `bool` | `true` | no |
| eks_cluster_name | Name of the EKS cluster. | `string` | `null` | no |
| enable_pod_identity | Whether to enable EKS Pod Identity. | `bool` | `false` | no |
| force_update | Whether to force update the Helm release. | `bool` | `false` | no |
| iam_openid_provider_arn | The ARN of the OpenID Connect (OIDC) provider associated with the EKS cluster. | `string` | `null` | no |
| iam_openid_provider_url | The URL of the OpenID Connect (OIDC) provider associated with the EKS cluster. | `string` | `null` | no |
| irsa_iam_role_name | Name of the IAM role for IRSA. | `string` | `null` | no |
| irsa_policy_json | JSON policy document for IRSA IAM role. | `string` | `null` | no |
| namespace | Kubernetes namespace to install the release into. Creates one if not present. | `string` | `"default"` | no |
| service_account_name | Name of the Kubernetes service account. | `string` | `null` | no |
| values | List of paths to Helm values files. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| irsa_role_arn | The ARN of the IAM role for IAM Roles for Service Accounts (IRSA), if created. |
| irsa_role_id | The ID of the IAM role for IAM Roles for Service Accounts (IRSA), if created. |

## How to Contribute

Open a pull request

## License

This module is licensed under the [MIT License](https://opensource.org/licenses/MIT).
<!-- END_TF_DOCS -->