# AWS
variable "aws_account" {
  type        = string
  description = "The AWS account ID where resources will be provisioned."
}

variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be provisioned."
}

# EKS
variable "cluster_name" {
  type        = string
  description = "The name of the Amazon EKS cluster."
}

variable "cluster_nodepool_name" {
  type        = string
  default     = "system"
  description = "The node pool name in the Amazon EKS cluster where all controllers will be installed."
}

variable "iam_openid_provider" {
  type = object({
    oidc_provider_arn = string
    oidc_provider     = string
  })
  default     = null
  description = "The IAM OIDC provider configuration for the EKS cluster."
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

variable "project_env" {
  type        = string
  default     = ""
  description = "The project environment (e.g., dev, staging, prod)."
}

variable "project_name" {
  type        = string
  default     = ""
  description = "The name of the project."
}

variable "notification_slack_token_secret" {
  type        = string
  default     = ""
  description = "AWS Secret Manager key to store a Slack token for notifications."
}

variable "services" {
  type = object({
    argocd = optional(object({
      enabled                         = bool
      helm_version                    = optional(string, "7.3.11")
      namespace                       = optional(string, "argocd")
      service_account_name            = optional(string, "argocd-sa")
      nodepool                        = optional(string, "system")
      additional_helm_values          = optional(string, "")
      notification_slack_token_secret = optional(string)
      argocd_url                      = optional(string)
      irsa_role_arn                   = optional(string)
      irsa_iam_role_name              = optional(string)
      custom_ingress                  = optional(string)
      custom_notifications            = optional(string)
      }), {
      enabled = false
    }),
    aws-alb-ingress-controller = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "1.8.1")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "aws-alb-ingress-controller-sa")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
      }), {
      enabled = false
    }),
    cluster-autoscaler = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "9.37.0")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "autoscaler-sa")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
      }), {
      enabled = false
    }),
    external-dns = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "1.14.5")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "external-dns-sa")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
      }), {
      enabled = false
    }),
    external-secrets = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "0.9.20")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "external-secrets-sa")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      irsa_iam_policy_json   = optional(string)
      }), {
      enabled = false
    }),
    karpenter = optional(object({
      enabled                             = optional(bool, false)
      helm_version                        = optional(string, "1.0.6")
      namespace                           = optional(string, "general")
      service_account_name                = optional(string, "karpenter")
      nodepool                            = optional(string, "system")
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
      default_nodepool_capacity_type      = optional(list(string), ["on-demand"])
      default_nodepool_yaml               = optional(string)
      default_nodeclass_yaml              = optional(string)
      irsa_iam_role_name                  = optional(string)
      node_iam_role_name                  = optional(string)
      node_security_group_id              = optional(string)
      }), {
      enabled = false
    }),
    keda = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "2.14.3")
      namespace              = optional(string, "general")
      service_account_name   = optional(string, "keda-sa")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      irsa_role_name         = optional(string)
      irsa_role_arn          = optional(string)
      irsa_iam_role_name     = optional(string)
      }), {
      enabled = false
    }),
    metrics-server = optional(object({
      enabled                = optional(bool, false)
      helm_version           = optional(string, "3.12.1")
      namespace              = optional(string, "general")
      nodepool               = optional(string, "system")
      additional_helm_values = optional(string, "")
      }), {
      enabled = false
    }),
  })
  description = "List of services and their parameters (version, configs, namespaces, etc.)."
}

variable "tags" {
  default     = {}
  type        = any
  description = "Resource tags."
}
