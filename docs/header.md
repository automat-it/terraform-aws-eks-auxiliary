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