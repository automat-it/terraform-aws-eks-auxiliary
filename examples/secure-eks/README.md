# Terraform Secure EKS

This example demonstrates the usage of the `eks-aux` module with an alternative approach to variable declarations, utilizing locals to reference necessary values.

> **Note:** The information provided in the root `README` is still valid and should be followed. This `README` contains additional details specific to this example.

## Usage

Refer to the root `README` for general guidance. This example's `eks-auxiliary.tf` already includes a reference to the module.

After the initial installation, you may want to **hardcode** certain addons or Helm versions for a production environment to prevent future drift and unexpected updates.

### Hardcoding EKS Addons Version

To specify an **EKS addon version**, add `addon_version` in the `eks.tf` file under the `cluster_addons` section:

```hcl
cluster_addons = {
  coredns = {
    most_recent   = true
    addon_version = "v1.18.6-eksbuild.1"
  }
}
```

### Hardcoding Helm Chart Versions

To specify a **Helm version** installed by the auxiliary module, add `helm_version` in the `services` section for the required service:

```hcl
services = {
  argocd = {
    enabled      = true
    helm_version = "7.3.11"
  }
}
```

## Managing Access Entries

By default, access is provided to a **default role** in the `access_entries` section. If additional access entries are needed, simply add a new block in this section.

The example below grants **AmazonEKSClusterAdminPolicy** permissions at the cluster level to a specified IAM user:

```hcl
user-admin = {
  principal_arn = "arn:aws:iam::${local.aws_account}:user/SOME_USER"
  type          = "STANDARD"

  policy_associations = {
    admin = {
      policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }
}
```

## Overwriting Helm Values

For all Helm charts installed by the auxiliary module, you can override some values if necessary.

To achieve this, use `additional_helm_values` in the relevant **service declaration**. The example below disables ingress creation for **ArgoCD**:

```hcl
services = {
  argocd = {
    enabled  = true
    nodepool = ""
    version  = "7.3.7"
    additional_helm_values = <<-EOF
      server:
        ingress:
          enabled: false
    EOF
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 21.3.2 |
| <a name="module_iam_role_ebs_csi_addon"></a> [iam\_role\_ebs\_csi\_addon](#module\_iam\_role\_ebs\_csi\_addon) | terraform-aws-modules/iam/aws//modules/iam-role | 6.2.1 |
| <a name="module_secure-eks"></a> [secure-eks](#module\_secure-eks) | github.com/automat-it/terraform-aws-eks-auxiliary.git | v1.33.1 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.alb-controller-sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [kubernetes_storage_class.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_ami_type"></a> [eks\_ami\_type](#input\_eks\_ami\_type) | ## EKS Common | `string` | n/a | yes |
| <a name="input_eks_attach_cluster_primary_security_group"></a> [eks\_attach\_cluster\_primary\_security\_group](#input\_eks\_attach\_cluster\_primary\_security\_group) | n/a | `bool` | n/a | yes |
| <a name="input_eks_instance_types"></a> [eks\_instance\_types](#input\_eks\_instance\_types) | n/a | `list(string)` | n/a | yes |
| <a name="input_eks_system_desired_size"></a> [eks\_system\_desired\_size](#input\_eks\_system\_desired\_size) | n/a | `number` | n/a | yes |
| <a name="input_eks_system_instance_types"></a> [eks\_system\_instance\_types](#input\_eks\_system\_instance\_types) | n/a | `list(string)` | n/a | yes |
| <a name="input_eks_system_max_size"></a> [eks\_system\_max\_size](#input\_eks\_system\_max\_size) | n/a | `number` | n/a | yes |
| <a name="input_eks_system_min_size"></a> [eks\_system\_min\_size](#input\_eks\_system\_min\_size) | System | `number` | n/a | yes |
| <a name="input_eks_worker_capacity_type"></a> [eks\_worker\_capacity\_type](#input\_eks\_worker\_capacity\_type) | n/a | `string` | n/a | yes |
| <a name="input_eks_worker_desired_size"></a> [eks\_worker\_desired\_size](#input\_eks\_worker\_desired\_size) | n/a | `number` | n/a | yes |
| <a name="input_eks_worker_instance_types"></a> [eks\_worker\_instance\_types](#input\_eks\_worker\_instance\_types) | n/a | `list(string)` | n/a | yes |
| <a name="input_eks_worker_max_size"></a> [eks\_worker\_max\_size](#input\_eks\_worker\_max\_size) | n/a | `number` | n/a | yes |
| <a name="input_eks_worker_min_size"></a> [eks\_worker\_min\_size](#input\_eks\_worker\_min\_size) | Worker | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->