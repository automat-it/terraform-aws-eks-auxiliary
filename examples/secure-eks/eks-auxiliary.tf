module "secure-eks" {
  source     = "github.com/automat-it/terraform-aws-eks-auxiliary.git?ref=v1.33.1"
  depends_on = [module.eks, module.mgmt-peering]

  # Components
  services = {
    argocd = {
      enabled                = true
      nodepool               = ""
      helm_version           = "8.0.0"
      additional_helm_values = <<-EOF
        server:
          ingress:
            enabled: false
      EOF
    }
    aws-alb-ingress-controller = {
      enabled                = true
      additional_helm_values = <<-EOF
      backendSecurityGroup: "${aws_security_group.alb-controller-sg.id}"
      EOF
    }
    cluster-autoscaler = {
      enabled = false
    }
    karpenter = {
      enabled = true
      # Optional Karpenter parameters
      node_security_group_id              = module.eks.node_security_group_id
      default_nodepool_capacity_type      = ["spot"]
      default_nodeclass_volume_size       = "30Gi"
      default_nodeclass_instance_category = ["t"]
    }
    external-dns = {
      enabled = true
    }
    external-secrets = {
      enabled = true
    }
    keda = {
      enabled = false
    }
    metrics-server = {
      enabled = true
    }
  }

  # AWS
  aws_region = local.aws_region
  account_id = local.account_id

  # EKS
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  iam_openid_provider = {
    oidc_provider_arn = module.eks.oidc_provider_arn
    oidc_provider     = module.eks.oidc_provider
  }

  # VPC
  vpc_id = module.vpc.vpc.id

  # DNS
  domain_zone = local.project_domain

  # Tags
  tags = {
    Managed_by  = "Terraform"
    Environment = "Development"
  }
}
