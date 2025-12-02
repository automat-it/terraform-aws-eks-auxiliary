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

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | >= 5.0 |
| helm | >= 3.1.0 |
| kubectl | >= 2.0 |
| kubernetes | >= 2.20 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_pod_identity_association.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_role.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.pod_identity](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chart | Helm chart name. | `string` | n/a | yes |
| helm_version | Helm chart version. | `string` | n/a | yes |
| name | Name of the Helm release. | `string` | n/a | yes |
| repository | Helm chart repository. | `string` | n/a | yes |
| create_irsa_role | Whether to create an IRSA role. | `string` | `true` | no |
| dependency_update | Whether to update dependencies. | `bool` | `true` | no |
| eks_cluster_name | Name of the EKS cluster. | `string` | `null` | no |
| enable_pod_identity | Whether to enable EKS Pod Identity. | `bool` | `false` | no |
| force_update | Whether to force update the Helm release. | `bool` | `false` | no |
| iam_openid_provider | EKS oidc provider values | ```object({ oidc_provider_arn = string oidc_provider = string })``` | `null` | no |
| irsa_iam_role_name | Name of the IAM role for IRSA. | `string` | `null` | no |
| irsa_policy_json | JSON policy document for IRSA IAM role. | `string` | `null` | no |
| namespace | Kubernetes namespace to install the release into. Creates one if not present. | `string` | `"default"` | no |
| repository_password | Helm chart repository password. | `string` | `null` | no |
| repository_username | Helm chart repository username. | `string` | `null` | no |
| service_account_name | Name of the Kubernetes service account. | `string` | `null` | no |
| skip_crds | Skip CRDs installing if they doesn't exist | `bool` | `false` | no |
| take_ownership | If set, allows Helm to adopt existing resources not marked as managed by the release. | `bool` | `true` | no |
| upgrade_install | If true, the provider will install the release at the specified version even if a release not controlled by the provider is present: this is equivalent to running 'helm upgrade --install' with the Helm CLI. | `bool` | `true` | no |
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
