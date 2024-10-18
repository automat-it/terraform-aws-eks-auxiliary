<!-- BEGIN_TF_DOCS -->
# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practicies. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.

## Usage

Include a reference to the directory of your Terraform environment where you configured the Amazon Elastic Kubernetes Service (EKS) cluster setup and set correct variables.

Reference values could be found at [examples directory](examples).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.4 |
| aws | >= 5.0 |
| helm | >= 2.9.0 |
| kubectl | >= 2.0 |
| kubernetes | >= 2.20 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| argocd | ./modules/helm-chart | n/a |
| argocd-backup | ./modules/argocd-s3-backup | n/a |
| aws-alb-ingress-controller | ./modules/helm-chart | n/a |
| cluster-autoscaler | ./modules/helm-chart | n/a |
| external-dns | ./modules/helm-chart | n/a |
| external-secrets | ./modules/helm-chart | n/a |
| karpenter | terraform-aws-modules/eks/aws//modules/karpenter | ~> 20.0 |
| karpenter-helm | ./modules/helm-chart | n/a |
| keda | ./modules/helm-chart | n/a |
| metrics-server | ./modules/helm-chart | n/a |
| slack-notifications | ./modules/argocd-slack-notification | n/a |

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.karpenter_default_node_class](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_default_node_pool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.argocd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.general](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.security](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_account | The AWS account ID where resources will be provisioned. | `string` | n/a | yes |
| aws_region | The AWS region where resources will be provisioned. | `string` | n/a | yes |
| cluster_name | The name of the Amazon EKS cluster. | `string` | n/a | yes |
| vpc_id | The ID of the Virtual Private Cloud (VPC) where resources will be deployed. | `string` | n/a | yes |
| argocd_custom_ingress | Custom ingress settings for ArgoCD. | `string` | `""` | no |
| backup_cron | Backup job schedule in crontab format. The default is daily at 1 AM. | `string` | `"0 1 * * *"` | no |
| cluster_nodepool_name | The node pool name in the Amazon EKS cluster where all controllers will be installed. | `string` | `"system"` | no |
| destination_s3_name | The name of the destination S3 bucket for backups. | `string` | `""` | no |
| destination_s3_name_prefix | The prefix for the S3 bucket destination for backups. | `string` | `"argocd"` | no |
| domain_zone | The domain zone associated with the Route 53 hosted zone. | `string` | `""` | no |
| enable_backup | Enable backup for ArgoCD. | `bool` | `false` | no |
| has_argocd | Whether ArgoCD will be installed. | `bool` | `false` | no |
| has_autoscaler | Whether the cluster autoscaler will be installed. | `bool` | `false` | no |
| has_aws_lb_controller | Whether the AWS Load Balancer Controller will be installed. | `bool` | `false` | no |
| has_external_dns | Whether the External DNS controller will be installed. | `bool` | `false` | no |
| has_external_secrets | Whether the External Secrets controller will be installed. | `bool` | `false` | no |
| has_karpenter | Whether Karpenter will be installed. | `bool` | `false` | no |
| has_keda | Whether KEDA (Kubernetes Event-driven Autoscaling) controller will be installed. | `bool` | `false` | no |
| has_metrics_server | Whether the Kubernetes Metrics Server will be installed. | `bool` | `true` | no |
| iam_openid_provider | The IAM OIDC provider configuration for the EKS cluster. | ```object({ oidc_provider_arn = string oidc_provider = string })``` | `null` | no |
| notification_slack_token_secret | AWS Secret Manager key to store a Slack token for notifications. | `string` | `""` | no |
| project_env | The project environment (e.g., dev, staging, prod). | `string` | `""` | no |
| project_name | The name of the project. | `string` | `""` | no |
| r53_zone_id | The ID of the Route 53 hosted zone, if DNS records are managed by Route 53. | `string` | `""` | no |
| services | List of services and their parameters (version, configs, namespaces, etc.). | `any` | `{}` | no |
| tags | Resource tags. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_controller_irsa_role_arn | The ARN of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts). |
| alb_controller_irsa_role_id | The ID of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts). |
| argocd_irsa_role_arn | The ARN of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts). |
| argocd_irsa_role_id | The ID of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts). |
| autoscaler_irsa_role_arn | The ARN of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts). |
| autoscaler_irsa_role_id | The ID of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts). |
| external_dns_irsa_role_arn | The ARN of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts). |
| external_dns_irsa_role_id | The ID of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts). |
| external_secrets_irsa_role_arn | The ARN of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts). |
| external_secrets_irsa_role_id | The ID of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts). |
| karpenter_default_node_class_name | The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| karpenter_irsa_role_arn | The ARN of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| karpenter_irsa_role_id | The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| karpenter_node_iam_role_name | The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| keda_irsa_role_arn | The ARN of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| keda_irsa_role_id | The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| metrics_server_irsa_role_arn | The ARN of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts). |
| metrics_server_irsa_role_id | The ID of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts). |

## How to Contribute

To add a component to the cluster module, follow these steps:

1. Place the component file in the root directory, e.g. [external-dns.tf](external-dns.tf).
2. Ensure that any required variables for the new component are added to the variables.tf file, like:
```terraform
variable "has_external_dns" { default = false }
```
3. Thoroughly test your changes to ensure proper functionality.
4. Once you've completed testing, submit a pull request with your changes for review and integration.
<!-- END_TF_DOCS -->