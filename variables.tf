# AWS
variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be provisioned."
}

# EKS
variable "cluster_name" {
  type        = string
  description = "The name of the Amazon EKS cluster."
}

variable "iam_openid_provider" {
  type = object({
    oidc_provider_arn = string
    oidc_provider     = string
  })
  default     = null
  description = "The IAM OIDC provider configuration for the EKS cluster."
}

variable "create_namespace_general" {
  type        = bool
  default     = true
  description = "Determines whether to create a general-purpose Kubernetes namespace. Set to 'true' to create the namespace, or 'false' to skip its creation."
}

variable "create_namespace_security" {
  type        = bool
  default     = true
  description = "Determines whether to create the security-related Kubernetes namespace. Set to 'true' to create the namespace, or 'false' to skip its creation."
}

# VPC
variable "vpc_id" {
  type        = string
  description = "The ID of the Virtual Private Cloud (VPC) where resources will be deployed."
}

# Route53
variable "r53_zone_id" {
  type        = string
  default     = ""
  description = "The ID of the Route 53 hosted zone, if DNS records are managed by Route 53."
}

variable "domain_zone" {
  type        = string
  default     = ""
  description = "The domain zone associated with the Route 53 hosted zone."
}

variable "services" {
  type = object({
    argocd = optional(object({
      enabled              = bool
      helm_version         = optional(string, "7.7.22")
      namespace            = optional(string, "argocd")
      service_account_name = optional(string, "argocd-sa")
      node_selector        = optional(map(string), { pool = "system" })
      tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values          = optional(string, "")
      load_balancer_name              = optional(string)
      load_balancer_group_name        = optional(string, "internal")
      load_balancer_scheme            = optional(string, "internal")
      notification_slack_token_secret = optional(string)
      argocd_url                      = optional(string)
      irsa_role_arn                   = optional(string)
      irsa_iam_role_name              = optional(string)
      custom_ingress                  = optional(string)
      custom_notifications            = optional(string)
    }), { enabled = false }),
    aws-alb-ingress-controller = optional(object({
      enabled                = bool
      helm_version           = optional(string, "1.9.2")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "aws-alb-ingress-controller-sa")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
    }), { enabled = false }),
    cluster-autoscaler = optional(object({
      enabled                = bool
      helm_version           = optional(string, "9.46.0")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "autoscaler-sa")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
    }), { enabled = false }),
    external-dns = optional(object({
      enabled                = bool
      helm_version           = optional(string, "1.15.1")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "external-dns-sa")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
    }), { enabled = false }),
    external-secrets = optional(object({
      enabled                = bool
      helm_version           = optional(string, "0.13.0")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "external-secrets-sa")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
    }), { enabled = false }),
    karpenter = optional(object({
      enabled                             = bool
      helm_version                        = optional(string, "1.2.0")
      namespace                           = optional(string, "general")
      service_account_name                = optional(string, "karpenter")
      node_selector                       = optional(map(string), { pool = "system" })
      additional_helm_values              = optional(string, "")
      deploy_default_nodeclass            = optional(bool, true)
      default_nodeclass_ami_family        = optional(string, "AL2023")
      default_nodeclass_ami_alias         = optional(string, "al2023@latest")
      default_nodeclass_name              = optional(string, "default")
      default_nodeclass_volume_size       = optional(string, "20Gi")
      default_nodeclass_volume_type       = optional(string, "gp3")
      default_nodeclass_instance_category = optional(list(string), ["t", "c", "m"])
      default_nodeclass_instance_cpu      = optional(list(string), ["2", "4"])
      deploy_default_nodepool             = optional(bool, true)
      default_nodepool_cpu_limit          = optional(string, "100")
      enable_budgets                      = optional(bool, false)
      budgets = optional(any, [
        { nodes = "10%" },
        { nodes = "3" },
        { nodes = "0", schedule = "0 9 * * sat-sun", duration = "24h" },
        { nodes = "0", schedule = "0 17 * * mon-fri", duration = "16h", reasons = ["Drifted"] }
      ])
      default_nodepool_capacity_type    = optional(list(string), ["on-demand"])
      default_nodepool_yaml             = optional(string)
      default_nodeclass_yaml            = optional(string)
      irsa_iam_role_name                = optional(string)
      node_iam_role_name                = optional(string)
      node_iam_role_additional_policies = optional(map(string), {})
      node_security_group_id            = optional(string)
    }), { enabled = false }),
    keda = optional(object({
      enabled                = bool
      helm_version           = optional(string, "2.16.1")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "keda-sa")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
    }), { enabled = false }),
    metrics-server = optional(object({
      enabled                = bool
      helm_version           = optional(string, "3.12.2")
      namespace              = optional(string, "general")
      node_selector          = optional(map(string), { pool = "system" })
      additional_helm_values = optional(string, "")
    }), { enabled = false }),
  })
  description = "List of services and their parameters (version, configs, namespaces, etc.)."
}

variable "tags" {
  default     = {}
  type        = any
  description = "Resource tags."
}
