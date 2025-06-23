module "secure-eks" {
  source = "github.com/automat-it/terraform-aws-eks-auxiliary.git"

  # Components
  services = {
    argocd = {
      enabled                = true
      nodepool               = ""
      version                = "7.3.7"
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

  # EKS
  cluster_name        = module.eks.cluster_name
  iam_openid_provider = module.eks

  # VPC
  vpc_id = module.vpc.vpc.id

  # DNS
  domain_zone = local.project_domain

  # Tags
  tags = {
    Managed_by  = "Terraform"
    Environment = "Development"
  }

  depends_on = [
    module.eks,
    module.vpc,
    module.private-subnets,
    module.isolated-subnets,
    module.public-subnets,
    module.tgw-attachment,
    module.tgw-sharing-attachment,
    module.tgw-peering-attachment,
    module.tgw-peering,
    module.tgw
  ]
}
