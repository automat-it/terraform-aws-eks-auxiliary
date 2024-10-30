<!-- BEGIN_TF_DOCS -->
# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practices. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.

## Usage

Include a reference to the directory of your Terraform environment where you configured the Amazon Elastic Kubernetes Service (EKS) cluster setup and set correct variables.

Reference values could be found at [examples directory](examples).

### Karpenter preparation
For Karpenter installation, please log out of the Amazon ECR Public registry before terraform apply, using this command:
```shell
helm registry logout public.ecr.aws
```
You can check why this step is necessary in [AWS Doc](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html#public-troubleshooting-authentication) and [Karpenter official manual](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#4-install-karpenter)

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | >= 5.0 |
| helm | >= 2.9.0 |
| kubectl | >= 2.0 |
| kubernetes | >= 2.20 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| argocd | ./modules/helm-chart | n/a |
| aws-alb-ingress-controller | ./modules/helm-chart | n/a |
| cluster-autoscaler | ./modules/helm-chart | n/a |
| external-dns | ./modules/helm-chart | n/a |
| external-secrets | ./modules/helm-chart | n/a |
| karpenter | terraform-aws-modules/eks/aws//modules/karpenter | 20.26.1 |
| karpenter-helm | ./modules/helm-chart | n/a |
| keda | ./modules/helm-chart | n/a |
| metrics-server | ./modules/helm-chart | n/a |

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
| services | List of services and their parameters (version, configs, namespaces, etc.). | ```object({ argocd = optional(object({ enabled = bool helm_version = optional(string, "7.3.11") namespace = optional(string, "argocd") service_account_name = optional(string, "argocd-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") load_balancer_name = optional(string) load_balancer_group_name = optional(string, "internal") load_balancer_scheme = optional(string, "internal") notification_slack_token_secret = optional(string) argocd_url = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) custom_ingress = optional(string) custom_notifications = optional(string) }), { enabled = false }), aws-alb-ingress-controller = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "1.8.1") namespace = optional(string, "general") service_account_name = optional(string, "aws-alb-ingress-controller-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), cluster-autoscaler = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "9.37.0") namespace = optional(string, "general") service_account_name = optional(string, "autoscaler-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), external-dns = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "1.14.5") namespace = optional(string, "general") service_account_name = optional(string, "external-dns-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), external-secrets = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "0.9.20") namespace = optional(string, "general") service_account_name = optional(string, "external-secrets-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), karpenter = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "1.0.6") namespace = optional(string, "general") service_account_name = optional(string, "karpenter") nodepool = optional(string, "system") additional_helm_values = optional(string, "") deploy_default_nodeclass = optional(bool, true) default_nodeclass_ami_family = optional(string, "AL2023") default_nodeclass_ami_alias = optional(string, "al2023@latest") default_nodeclass_name = optional(string, "default") default_nodeclass_volume_size = optional(string, "20Gi") default_nodeclass_volume_type = optional(string, "gp3") default_nodeclass_instance_category = optional(list(string), ["t", "c", "m"]) default_nodeclass_instance_cpu = optional(list(string), ["2", "4"]) deploy_default_nodepool = optional(bool, true) default_nodepool_cpu_limit = optional(string, "100") default_nodepool_capacity_type = optional(list(string), ["on-demand"]) default_nodepool_yaml = optional(string) default_nodeclass_yaml = optional(string) irsa_iam_role_name = optional(string) node_iam_role_name = optional(string) node_security_group_id = optional(string) }), { enabled = false }), keda = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "2.14.3") namespace = optional(string, "general") service_account_name = optional(string, "keda-sa") nodepool = optional(string, "system") additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) }), { enabled = false }), metrics-server = optional(object({ enabled = optional(bool, false) helm_version = optional(string, "3.12.1") namespace = optional(string, "general") nodepool = optional(string, "system") additional_helm_values = optional(string, "") }), { enabled = false }), })``` | n/a | yes |
| vpc_id | The ID of the Virtual Private Cloud (VPC) where resources will be deployed. | `string` | n/a | yes |
| cluster_nodepool_name | The node pool name in the Amazon EKS cluster where all controllers will be installed. | `string` | `"system"` | no |
| domain_zone | The domain zone associated with the Route 53 hosted zone. | `string` | `""` | no |
| iam_openid_provider | The IAM OIDC provider configuration for the EKS cluster. | ```object({ oidc_provider_arn = string oidc_provider = string })``` | `null` | no |
| notification_slack_token_secret | AWS Secret Manager key to store a Slack token for notifications. | `string` | `""` | no |
| project_env | The project environment (e.g., dev, staging, prod). | `string` | `""` | no |
| project_name | The name of the project. | `string` | `""` | no |
| r53_zone_id | The ID of the Route 53 hosted zone, if DNS records are managed by Route 53. | `string` | `""` | no |
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
| karpenter_default_node_class_name | The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts). |
| karpenter_irsa_role_arn | The ARN of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts). |
| karpenter_irsa_role_id | The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts). |
| karpenter_node_iam_role_arn | The ARN of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts). |
| karpenter_node_iam_role_id | The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts). |
| keda_irsa_role_arn | The ARN of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| keda_irsa_role_id | The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts). |
| metrics_server_irsa_role_arn | The ARN of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts). |
| metrics_server_irsa_role_id | The ID of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts). |

## How to Contribute

To add a service to the module, follow these steps:

1. Place the component file for new service in the root directory, e.g. [external-dns.tf](external-dns.tf).
2. Ensure that any required variables for the new component are added to the services variable in [variables.tf](variables.tf?plain=1#L70) file, like:
```terraform
variable "services" {
  type = object({
    new_service = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "version")
      namespace              = optional(string, "namespace")
      nodepool               = optional(string, "nodepool")
      additional_helm_values = optional(string, "")
      }), {
      enabled = false
    }),
  })
}
```
3. Add outputs for new service to [outputs.tf](outputs.tf) file, like:
```terraform
output "new_service_irsa_role_arn" {
  description = "The ARN of the IAM role used by the New service for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.new_service.enabled ? module.new_service[0].irsa_role_arn : null
}

output "new_service_irsa_role_id" {
  description = "The ID of the IAM role used by the New service for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.new_service.enabled ? module.new_service[0].irsa_role_id : null
}
```
4. Thoroughly test your changes to ensure proper functionality.
5. Once you've completed testing, submit a pull request with your changes for review and integration.
<!-- END_TF_DOCS -->