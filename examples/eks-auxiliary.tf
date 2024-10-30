module "eks-aux" {

  source = "../"

  project_env  = "test"
  project_name = "eks-aux"

  # Components
  services = {
    argocd = {
      enabled  = true
      nodepool = ""
      version  = "7.3.7"
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
      node_security_group_id                        = module.eks.node_security_group_id
      karpenetr_default_nodepool_capacity_type      = ["spot"]
      karpenetr_default_nodeclass_volume_size       = "30Gi"
      karpenetr_default_nodeclass_instance_category = ["t"]
    }
    external-dns = {
      enabled = true
    }
    external-secrets = {
      enabled = true
    }
    keda = {
      enabled = true
    }
    metrics-server = {
      enabled = true
    }
  }

  # AWS
  aws_account = var.aws_account_id
  aws_region  = var.aws_region

  # EKS
  cluster_name        = module.eks.cluster_name
  iam_openid_provider = module.eks

  # VPC
  vpc_id = var.vpc_id

  # DNS
  r53_zone_id = var.r53_zone_id
  domain_zone = var.domain_zone

  depends_on = [
    module.eks
  ]
}
