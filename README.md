<!-- BEGIN_TF_DOCS -->
# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practicies. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.

## Usage

Include a reference to the directory of your Terraform environment where you configured the Amazon Elastic Kubernetes Service (EKS) cluster setup and set correct variables.

Reference values could be found at [examples directory](examples).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.47 |
| helm | >= 2.9.0 |
| kubernetes | >= 2.20 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aws-alb-ingress-controller | ./modules/helm-chart | n/a |
| cluster-autoscaler | ./modules/helm-chart | n/a |
| external-dns | ./modules/helm-chart | n/a |
| external-secrets | ./modules/helm-chart | n/a |
| metrics-server | ./modules/helm-chart | n/a |
| monitoring | ./helm-charts/otl-agent-monitoring | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.eks-admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [kubernetes_namespace.general](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.security](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_account | The AWS account ID where resources will be provisioned. | `string` | n/a | yes |
| aws_region | The AWS region where resources will be provisioned. | `string` | n/a | yes |
| basename | The base name used for creating resource names or identifiers. | `string` | n/a | yes |
| cluster_name | The name of the Amazon EKS cluster. | `string` | n/a | yes |
| iam_openid_provider_arn | The ARN of the IAM OIDC identity provider for the cluster. | `string` | n/a | yes |
| iam_openid_provider_url | The URL of the IAM OIDC identity provider for the cluster. | `string` | n/a | yes |
| vpc_id | The ID of the Virtual Private Cloud (VPC) where resources will be deployed. | `string` | n/a | yes |
| domain_zone | The domain zone associated with the Route 53 hosted zone. | `string` | `""` | no |
| has_autoscaler | Whether the cluster autoscaler will be installed. | `bool` | `false` | no |
| has_aws_lb_controller | Whether the AWS Load Balancer Controller will be installed. | `bool` | `false` | no |
| has_external_dns | Whether the External DNS controller will be installed. | `bool` | `false` | no |
| has_external_secrets | Whether the Kubernetes Metrics Server will be installed. | `bool` | `false` | no |
| has_metrics_server | Whether the External Secrets controller will be installed. | `bool` | `true` | no |
| has_monitoring | Whether monitoring components will be installed. | `bool` | `false` | no |
| monitoring_config | Configuration map for the monitoring will be installed. | `any` | `{}` | no |
| r53_zone_id | The ID of the Route 53 hosted zone, if DNS records are managed by Route 53. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_controller_irsa_role_arn | The ARN of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts). |
| alb_controller_irsa_role_id | The ID of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts). |
| autoscaler_irsa_role_arn | The ARN of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts). |
| autoscaler_irsa_role_id | The ID of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts). |
| external_dns_irsa_role_arn | The ARN of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts). |
| external_dns_irsa_role_id | The ID of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts). |
| external_secrets_irsa_role_arn | The ARN of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts). |
| external_secrets_irsa_role_id | The ID of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts). |
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