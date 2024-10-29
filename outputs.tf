output "alb_controller_irsa_role_arn" {
  description = "The ARN of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.aws-alb-ingress-controller.enabled ? module.aws-alb-ingress-controller[0].irsa_role_arn : null
}

output "alb_controller_irsa_role_id" {
  description = "The ID of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.aws-alb-ingress-controller.enabled ? module.aws-alb-ingress-controller[0].irsa_role_id : null
}

output "autoscaler_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.cluster-autoscaler.enabled ? module.cluster-autoscaler[0].irsa_role_arn : null
}

output "autoscaler_irsa_role_id" {
  description = "The ID of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.cluster-autoscaler.enabled ? module.cluster-autoscaler[0].irsa_role_id : null
}

output "external_dns_irsa_role_arn" {
  description = "The ARN of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.external-dns.enabled ? module.external-dns[0].irsa_role_arn : null
}

output "external_dns_irsa_role_id" {
  description = "The ID of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.external-dns.enabled ? module.external-dns[0].irsa_role_id : null
}

output "external_secrets_irsa_role_arn" {
  description = "The ARN of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.external-secrets.enabled ? module.external-secrets[0].irsa_role_arn : null
}

output "external_secrets_irsa_role_id" {
  description = "The ID of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.external-secrets.enabled ? module.external-secrets[0].irsa_role_id : null
}

output "metrics_server_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.metrics-server.enabled ? module.metrics-server[0].irsa_role_arn : null
}

output "metrics_server_irsa_role_id" {
  description = "The ID of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.metrics-server.enabled ? module.metrics-server[0].irsa_role_id : null
}

output "argocd_irsa_role_arn" {
  description = "The ARN of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.argocd.enabled ? module.argocd[0].irsa_role_arn : null
}

output "argocd_irsa_role_id" {
  description = "The ID of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.argocd.enabled ? module.argocd[0].irsa_role_id : null
}

output "keda_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.keda.enabled ? module.keda[0].irsa_role_arn : null
}

output "keda_irsa_role_id" {
  description = "The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.keda.enabled ? module.keda[0].irsa_role_id : null
}

output "karpenter_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].iam_role_arn : null
}

output "karpenter_irsa_role_id" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].iam_role_name : null
}

output "karpenter_node_iam_role_name" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].node_iam_role_name : null
}

output "karpenter_default_node_class_name" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? var.services.karpenter.default_nodeclass_name : null
}
