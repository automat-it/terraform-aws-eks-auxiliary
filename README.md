<!-- BEGIN_TF_DOCS -->
# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practices. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.

## Usage

Include a reference to the directory of your Terraform environment where you configured the Amazon Elastic Kubernetes Service (EKS) cluster setup and set correct variables.

Reference values could be found at [examples directory](examples).

### Karpenter preparation

Please consider adding the proper tag for the Karpenter subnet autodiscovery. We usually associate these tags with the private AWS Subnets:

```hcl
tags = merge(local.base_tags, {
    Tier                                              = "Private"
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/<Your EKS cluster name>"   = "shared"
    "karpenter.sh/discovery"                          = "<Your EKS cluster name>"
  })
```

Unless your AWS account has already been onboarded to EC2 Spot, you will need to create the service-linked role to avoid ServiceLinkedRoleCreationNotPermitted issue:

```shell
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

For Karpenter installation, please log out of the Amazon ECR Public registry before terraform apply, using this command:

```shell
helm registry logout public.ecr.aws
```

You can check why these steps are necessary in [AWS Doc](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html#public-troubleshooting-authentication), [Karpenter official manual](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#4-install-karpenter), [Karpenter troubleshooting](https://karpenter.sh/docs/troubleshooting/#missing-service-linked-role)

### Karpenter CRD migration

In v1.31.2 karpenter crd installation as separate helm chart was introduced. It was done to handle crd update issue in karpenter future karpenter updates.
If you have already installed karpenter with this module, we advising to migrate existed CRDs under TF managing.
To do this please follow these steps:

1. Update module version to `=> 1.31.2` and set this parameters `manage_crd = true` as in snippet above

```hcl
module "eks-aux" {
  source = "git@github.com:automat-it/terraform-aws-eks-auxiliary.git?ref=v1.31.2"
  module "secure-eks" {
    }
    karpenter = {
      enabled                      = true
      manage_crd                   = true
      ...
    }
    ...
}
```

2. Update CRDs (EC2NodeClass,NodePool,NodeClaim) in cluster with these metadata

```yaml
metadata:
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    app.kubernetes.io/managed-by: Helm
    meta.helm.sh/release-name: karpenter-crd
    meta.helm.sh/release-namespace: general
```

3. Run terraform plan and check drift. It will propose you to install new helm chart called karpenter-crd.
4. Run terraform apply. As a result TF will start manage old CRDs under new entity in state that we created and at the same time no changes would done on infra.
After all steps will be done you are free to update karpenter version using this module, CRDs will be updated automatically

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
| karpenter-crd-helm | ./modules/helm-chart | n/a |
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
| aws_region | The AWS region where resources will be provisioned. | `string` | n/a | yes |
| cluster_name | The name of the Amazon EKS cluster. | `string` | n/a | yes |
| services | List of services and their parameters (version, configs, namespaces, etc.). | ```object({ argocd = optional(object({ enabled = bool chart_name = optional(string, "argocd") helm_version = optional(string, "7.8.8") namespace = optional(string, "argocd") service_account_name = optional(string, "argocd-sa") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) create_namespace = optional(bool, true) additional_helm_values = optional(string, "") load_balancer_name = optional(string) load_balancer_group_name = optional(string, "internal") load_balancer_scheme = optional(string, "internal") notification_slack_token_secret = optional(string) argocd_url = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) custom_ingress = optional(string) custom_notifications = optional(string) }), { enabled = false }), aws-alb-ingress-controller = optional(object({ enabled = bool chart_name = optional(string, "aws-alb-ingress-controller") helm_version = optional(string, "1.11.0") namespace = optional(string, "general") service_account_name = optional(string, "aws-alb-ingress-controller-sa") default_ssl_policy = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), cluster-autoscaler = optional(object({ enabled = bool chart_name = optional(string, "cluster-autoscaler") helm_version = optional(string, "9.46.2") namespace = optional(string, "general") service_account_name = optional(string, "autoscaler-sa") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), external-dns = optional(object({ enabled = bool chart_name = optional(string, "external-dns") helm_version = optional(string, "1.15.2") namespace = optional(string, "general") service_account_name = optional(string, "external-dns-sa") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), external-secrets = optional(object({ chart_name = optional(string, "external-secrets") enabled = bool helm_version = optional(string, "0.14.3") namespace = optional(string, "general") service_account_name = optional(string, "external-secrets-sa") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), karpenter = optional(object({ chart_name = optional(string, "karpenter") chart_crd_name = optional(string, "karpenter-crd") enabled = bool helm_version = optional(string, "1.4.0") manage_crd = optional(bool, false) # Whether to directly manage CRD by Terraform. If false, CRD will be installed by the karpenter helm by dependency. If true, CRD will be installed with additional helm via terraform. Reference: https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter-crd namespace = optional(string, "general") service_account_name = optional(string, "karpenter") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") crd_additional_helm_values = optional(string, "") deploy_default_nodeclass = optional(bool, true) default_nodeclass_ami_family = optional(string, "AL2023") default_nodeclass_ami_alias = optional(string, "al2023@latest") default_nodeclass_name = optional(string, "default") http_put_response_hop_limit = optional(string, "2") default_nodeclass_volume_size = optional(string, "20Gi") default_nodeclass_volume_type = optional(string, "gp3") default_nodeclass_instance_category = optional(list(string), ["t", "c", "m"]) default_nodeclass_instance_cpu = optional(list(string), ["2", "4"]) deploy_default_nodepool = optional(bool, true) default_nodepool_cpu_limit = optional(string, "100") enable_budgets = optional(bool, false) budgets = optional(any, [ { nodes = "10%" }, { nodes = "3" }, { nodes = "0", schedule = "0 9 * * sat-sun", duration = "24h" }, { nodes = "0", schedule = "0 17 * * mon-fri", duration = "16h", reasons = ["Drifted"] } ]) default_nodepool_capacity_type = optional(list(string), ["on-demand"]) default_nodepool_yaml = optional(string) default_nodeclass_yaml = optional(string) irsa_iam_role_name = optional(string) node_iam_role_name = optional(string) node_iam_role_additional_policies = optional(map(string), {}) node_iam_role_additional_tags = optional(map(string), {}) node_security_group_id = optional(string) }), { enabled = false }), keda = optional(object({ chart_name = optional(string, "keda") enabled = bool helm_version = optional(string, "2.16.1") namespace = optional(string, "general") service_account_name = optional(string, "keda-sa") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") irsa_role_name = optional(string) irsa_role_arn = optional(string) irsa_iam_role_name = optional(string) irsa_iam_policy_json = optional(string) }), { enabled = false }), metrics-server = optional(object({ chart_name = optional(string, "metrics-server") enabled = bool helm_version = optional(string, "3.12.2") namespace = optional(string, "general") node_selector = optional(map(string), { pool = "system" }) additional_tolerations = optional(list(object({ key = string operator = optional(string, "Equal") value = string effect = optional(string, "NoSchedule") tolerationSeconds = optional(number, null) }))) additional_helm_values = optional(string, "") }), { enabled = false }), })``` | n/a | yes |
| vpc_id | The ID of the Virtual Private Cloud (VPC) where resources will be deployed. | `string` | n/a | yes |
| create_namespace_general | Determines whether to create a general-purpose Kubernetes namespace. Set to 'true' to create the namespace, or 'false' to skip its creation. | `bool` | `true` | no |
| create_namespace_security | Determines whether to create the security-related Kubernetes namespace. Set to 'true' to create the namespace, or 'false' to skip its creation. | `bool` | `true` | no |
| domain_zone | The domain zone associated with the Route 53 hosted zone. | `string` | `""` | no |
| iam_openid_provider | The IAM OIDC provider configuration for the EKS cluster. | ```object({ oidc_provider_arn = string oidc_provider = string })``` | `null` | no |
| node_class_additional_tags | Additional tags, that will be assigned to the NodeClass. | `map(string)` | `{}` | no |
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
```hcl
variable "services" {
  type = object({
    new_service = optional(object({
      enabled                = bool
      helm_version           = optional(string, "version")
      namespace              = optional(string, "namespace")
      nodepool               = optional(string, "nodepool")
      additional_helm_values = optional(string, "")
      }), { enabled = false }),
  })
}
```
3. Add outputs for new service to [outputs.tf](outputs.tf) file, like:
```hcl
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
