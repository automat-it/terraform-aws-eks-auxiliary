variable "name" {
  description = "Name of the Helm release."
  type        = string
}

variable "repository" {
  description = "Helm chart repository."
  type        = string
}

variable "repository_username" {
  description = "Helm chart repository username."
  type        = string
  default     = null
}

variable "repository_password" {
  description = "Helm chart repository password."
  type        = string
  default     = null
}

variable "chart" {
  description = "Helm chart name."
  type        = string
}

variable "skip_crds" {
  description = "Skip CRDs installing if they doesn't exist"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Kubernetes namespace to install the release into. Creates one if not present."
  type        = string
  default     = "default"
}

variable "helm_version" {
  description = "Helm chart version."
  type        = string
}

variable "dependency_update" {
  description = "Whether to update dependencies."
  type        = bool
  default     = true
}

variable "force_update" {
  description = "Whether to force update the Helm release."
  type        = bool
  default     = false
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account."
  type        = string
  default     = null
}

variable "values" {
  description = "List of paths to Helm values files."
  type        = list(string)
  default     = []
}

variable "iam_openid_provider" {
  description = "EKS oidc provider values"
  type = object({
    oidc_provider_arn = string
    oidc_provider     = string
  })
  default = null
}

variable "create_irsa_role" {
  description = "Whether create IRSA role."
  type        = string
  default     = true
}

variable "irsa_iam_role_name" {
  description = "Name of the IAM role for IRSA."
  type        = string
  default     = null
}

variable "irsa_policy_json" {
  description = "JSON policy document for IRSA IAM role."
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = null
}

variable "enable_pod_identity" {
  description = "Whether to enable EKS Pod Identity."
  type        = bool
  default     = false
}
