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

