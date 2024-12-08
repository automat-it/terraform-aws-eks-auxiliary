# Terraform EKS Auxiliary

The provided Terraform code defines Helm charts and infrastructure components for managing EKS cluster along with associated resources such as IAM roles, Kubernetes namespaces, and monitoring according to Automat-IT best practices. It provides infrastructure components (like Ingress, load balancing, scaling, monitoring, secrets, and DNS) necessary for setting up and managing EKS cluster.


## Usage

Include a reference to the directory of your Terraform environment where you configured the Amazon Elastic Kubernetes Service (EKS) cluster setup and set correct variables.

Reference values could be found at [examples directory](examples).

### Karpenter preparation
Please consider adding the proper tag for the Karpenter subnet autodiscovery. We usually associate these tags with the private subnets:
```shell
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
