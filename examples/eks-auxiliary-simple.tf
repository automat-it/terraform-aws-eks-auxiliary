module "eks-aux-simple" {

  source = "../"

  # Components: Install only Cluster-autoscaler and Keda controller
  services = {
    cluster-autoscaler = {
      enabled = true
    }
    keda = {
      enabled = true
    }
  }

  # AWS
  aws_region = var.aws_region

  # EKS
  cluster_name        = module.eks.cluster_name
  iam_openid_provider = module.eks

  # VPC
  vpc_id = var.vpc_id

  # DNS
  r53_zone_id = var.r53_zone_id
  domain_zone = var.domain_zone

  # Tags
  tags = {
    Managed_by  = "Terraform"
    Environment = "Development"
  }

  depends_on = [
    module.eks
  ]
}
