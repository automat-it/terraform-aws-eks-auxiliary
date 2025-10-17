# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practices. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.

> **Note:** This branch is following Terraform AWS 5.x Provider Version ONLY. For AWS Provider 6.x compatibility, please checkout the `main` branch.

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
docker logout public.ecr.aws
```

You can check why these steps are necessary in [AWS Doc](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html#public-troubleshooting-authentication), [Karpenter official manual](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#4-install-karpenter), [Karpenter troubleshooting](https://karpenter.sh/docs/troubleshooting/#missing-service-linked-role)

`"alekc/kubectl"` is the only tested source for the `kubectl` TF provider.

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
