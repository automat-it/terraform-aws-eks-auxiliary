output "alb_controller_iam_role_arn" {
  description = "The ARN of the IAM role used by the AWS Load Balancer Controller (IAM Roles for Service Accounts)."
  value       = var.services.aws-alb-ingress-controller.enabled ? module.aws-alb-ingress-controller[0].iam_role_arn : null
}

output "alb_controller_role_id" {
  description = "The ID of the IAM role used by the AWS Load Balancer Controller (IAM Roles for Service Accounts)."
  value       = var.services.aws-alb-ingress-controller.enabled ? module.aws-alb-ingress-controller[0].iam_role_id : null
}

output "autoscaler_iam_role_arn" {
  description = "The ARN of the IAM role used by the Cluster Autoscaler (IAM Roles for Service Accounts)."
  value       = var.services.cluster-autoscaler.enabled ? module.cluster-autoscaler[0].iam_role_arn : null
}

output "autoscaler_role_id" {
  description = "The ID of the IAM role used by the Cluster Autoscaler (IAM Roles for Service Accounts)."
  value       = var.services.cluster-autoscaler.enabled ? module.cluster-autoscaler[0].iam_role_id : null
}

output "external_dns_iam_role_arn" {
  description = "The ARN of the IAM role used by the External DNS controller (IAM Roles for Service Accounts)."
  value       = var.services.external-dns.enabled ? module.external-dns[0].iam_role_arn : null
}

output "external_dns_role_id" {
  description = "The ID of the IAM role used by the External DNS controller (IAM Roles for Service Accounts)."
  value       = var.services.external-dns.enabled ? module.external-dns[0].iam_role_id : null
}

output "external_secrets_iam_role_arn" {
  description = "The ARN of the IAM role used by the External Secrets controller (IAM Roles for Service Accounts)."
  value       = var.services.external-secrets.enabled ? module.external-secrets[0].iam_role_arn : null
}

output "external_secrets_role_id" {
  description = "The ID of the IAM role used by the External Secrets controller (IAM Roles for Service Accounts)."
  value       = var.services.external-secrets.enabled ? module.external-secrets[0].iam_role_id : null
}

output "metrics_server_iam_role_arn" {
  description = "The ARN of the IAM role used by the Metrics Server for (IAM Roles for Service Accounts)."
  value       = var.services.metrics-server.enabled ? module.metrics-server[0].iam_role_arn : null
}

output "metrics_server_role_id" {
  description = "The ID of the IAM role used by the Metrics Server (IAM Roles for Service Accounts)."
  value       = var.services.metrics-server.enabled ? module.metrics-server[0].iam_role_id : null
}

output "argocd_iam_role_arn" {
  description = "The ARN of the IAM role used by the ArgoCD (IAM Roles for Service Accounts)."
  value       = var.services.argocd.enabled ? module.argocd[0].iam_role_arn : null
}

output "argocd_role_id" {
  description = "The ID of the IAM role used by the ArgoCD (IAM Roles for Service Accounts)."
  value       = var.services.argocd.enabled ? module.argocd[0].iam_role_id : null
}

output "keda_iam_role_arn" {
  description = "The ARN of the IAM role used by the Keda (IAM Roles for Service Accounts)."
  value       = var.services.keda.enabled ? module.keda[0].iam_role_arn : null
}

output "keda_role_id" {
  description = "The ID of the IAM role used by the Keda for (IAM Roles for Service Accounts)."
  value       = var.services.keda.enabled ? module.keda[0].iam_role_id : null
}

output "karpenter_iam_role_arn" {
  description = "The ARN of the IAM role used by the Karpenter for (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].iam_role_arn : null
}

output "karpenter_role_id" {
  description = "The ID of the IAM role used by the Karpenter for (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].iam_role_name : null
}

output "karpenter_node_iam_role_arn" {
  description = "The ARN of the IAM role used by the Karpenter for (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].node_iam_role_arn : null
}

output "karpenter_node_iam_role_id" {
  description = "The ID of the IAM role used by the Karpenter for (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? module.karpenter[0].node_iam_role_name : null
}

output "karpenter_default_node_class_name" {
  description = "The ID of the IAM role used by the Karpenter for (IAM Roles for Service Accounts)."
  value       = var.services.karpenter.enabled ? var.services.karpenter.default_nodeclass_name : null
}

output "karpenter_sqs_queue_arn" {
  description = "The ARN of the SQS queue used by the Karpenter for node termination."
  value       = !var.services.karpenter.enabled ? "" : module.karpenter[0].queue_arn
}
