# AWS
variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be provisioned."
}


variable "account_id" {
  type        = string
  description = "The AWS account id where resources will be provisioned."
}

# EKS
variable "cluster_name" {
  type        = string
  description = "The name of the Amazon EKS cluster."
}

variable "cluster_endpoint" {
  type        = string
  description = "The endpoint of the Amazon EKS cluster."
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

variable "node_class_additional_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags, that will be assigned to the NodeClass."
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
      chart_name           = optional(string, "argocd")
      helm_version         = optional(string, "9.0.5")
      namespace            = optional(string, "argocd")
      service_account_name = optional(string, "argocd-sa")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      create_namespace                = optional(bool, true)
      additional_helm_values          = optional(string, "")
      load_balancer_name              = optional(string)
      load_balancer_group_name        = optional(string, "internal")
      load_balancer_scheme            = optional(string, "internal")
      notification_slack_token_secret = optional(string)
      argocd_url                      = optional(string)
      iam_role_arn                    = optional(string)
      iam_role_name                   = optional(string)
      custom_ingress                  = optional(string)
      custom_notifications            = optional(string)
    }), { enabled = false }),
    aws-alb-ingress-controller = optional(object({
      enabled              = bool
      chart_name           = optional(string, "aws-alb-ingress-controller")
      helm_version         = optional(string, "1.14.1")
      namespace            = optional(string, "general")
      service_account_name = optional(string, "aws-alb-ingress-controller-sa")
      default_ssl_policy   = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
      iam_role_arn           = optional(string)
      iam_role_name          = optional(string)
      iam_policy_json        = optional(string)
    }), { enabled = false }),
    cluster-autoscaler = optional(object({
      enabled              = bool
      chart_name           = optional(string, "cluster-autoscaler")
      helm_version         = optional(string, "9.52.1")
      namespace            = optional(string, "general")
      service_account_name = optional(string, "autoscaler-sa")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
      iam_role_arn           = optional(string)
      iam_role_name          = optional(string)
      iam_policy_json        = optional(string)
    }), { enabled = false }),
    external-dns = optional(object({
      enabled              = bool
      chart_name           = optional(string, "external-dns")
      helm_version         = optional(string, "1.19.0")
      namespace            = optional(string, "general")
      service_account_name = optional(string, "external-dns-sa")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
      iam_role_arn           = optional(string)
      iam_role_name          = optional(string)
      iam_policy_json        = optional(string)
    }), { enabled = false }),
    external-secrets = optional(object({
      chart_name           = optional(string, "external-secrets")
      enabled              = bool
      helm_version         = optional(string, "0.20.4")
      namespace            = optional(string, "general")
      service_account_name = optional(string, "external-secrets-sa")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
      iam_role_arn           = optional(string)
      iam_role_name          = optional(string)
      iam_policy_json        = optional(string)
    }), { enabled = false }),
    karpenter = optional(object({
      chart_name           = optional(string, "karpenter")
      chart_crd_name       = optional(string, "karpenter-crd")
      enabled              = bool
      helm_version         = optional(string, "1.8.2")
      manage_crd           = optional(bool, false) # Whether to directly manage CRD by Terraform. If false, CRD will be installed by the karpenter helm by dependency. If true, CRD will be installed with additional helm via terraform. Reference: https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter-crd
      namespace            = optional(string, "general")
      service_account_name = optional(string, "karpenter")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values                     = optional(string, "")
      crd_additional_helm_values                 = optional(string, "")
      deploy_default_nodeclass                   = optional(bool, true)
      default_nodeclass_max_pods                 = optional(string)
      default_nodeclass_pods_per_core            = optional(string)
      default_nodeclass_ami_family               = optional(string, "AL2023")
      default_nodeclass_ami_alias                = optional(string, "al2023@latest")
      default_nodeclass_name                     = optional(string, "default")
      http_put_response_hop_limit                = optional(string, "2")
      default_nodeclass_volume_size              = optional(string, "20Gi")
      default_nodeclass_volume_type              = optional(string, "gp3")
      deploy_default_nodepool                    = optional(bool, true)
      default_nodepool_instance_category         = optional(list(string), ["t", "c", "m"])
      default_nodepool_instance_cpu              = optional(list(string), ["2", "4"])
      default_nodepool_instance_generation       = optional(list(string), [])
      default_nodepool_instance_cpu_manufacturer = optional(list(string), [])
      default_nodepool_cpu_limit                 = optional(string, "100")
      consolidation_policy                       = optional(string)
      additional_nodepools_yaml                  = optional(map(any), {})
      additional_nodepools_yaml                  = optional(map(any), {})
      enable_budgets                             = optional(bool, false)
      budgets = optional(any, [
        { nodes = "10%" },
        { nodes = "3" },
        { nodes = "0", schedule = "0 9 * * sat-sun", duration = "24h" },
        { nodes = "0", schedule = "0 17 * * mon-fri", duration = "16h", reasons = ["Drifted"] }
      ])
      default_nodepool_capacity_type        = optional(list(string), ["on-demand"])
      default_nodepool_yaml                 = optional(string)
      default_nodeclass_yaml                = optional(string)
      create_iam_role                       = optional(bool, true)
      iam_role_name                         = optional(string)
      iam_role_arn                          = optional(string)
      irsa_iam_role_additional_policies     = optional(map(string), {})
      create_node_iam_role                  = optional(bool, true)
      create_access_entry_for_node_iam_role = optional(bool, true)
      node_iam_role_name                    = optional(string)
      node_iam_role_additional_policies     = optional(map(string), {})
      node_iam_role_additional_tags         = optional(map(string), {})
      node_security_group_id                = optional(string)
    }), { enabled = false }),
    keda = optional(object({
      chart_name           = optional(string, "keda")
      enabled              = bool
      helm_version         = optional(string, "2.18.1")
      namespace            = optional(string, "general")
      service_account_name = optional(string, "keda-sa")
      node_selector        = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
      iam_role_arn           = optional(string)
      iam_role_name          = optional(string)
      iam_policy_json        = optional(string)
    }), { enabled = false }),
    metrics-server = optional(object({
      chart_name    = optional(string, "metrics-server")
      enabled       = bool
      helm_version  = optional(string, "3.13.0")
      namespace     = optional(string, "general")
      node_selector = optional(map(string), { pool = "system" })
      additional_tolerations = optional(list(object({
        key               = string
        operator          = optional(string, "Equal")
        value             = string
        effect            = optional(string, "NoSchedule")
        tolerationSeconds = optional(number, null)
      })))
      additional_helm_values = optional(string, "")
    }), { enabled = false }),
  })
  description = "List of services and their parameters (version, configs, namespaces, etc.)."

  validation {
    condition = (
      !try(var.services.karpenter.enabled, false)
      || (
        try(var.services.karpenter.enabled, false)
        && try(var.services.karpenter.node_security_group_id != null && var.services.karpenter.node_security_group_id != "", false)
      )
    )
    error_message = "When karpenter.enabled = true, you must set karpenter.node_security_group_id."
  }
}

variable "tags" {
  type        = any
  default     = {}
  description = "Resource tags."
}
