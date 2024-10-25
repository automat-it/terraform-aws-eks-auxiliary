output "alb_controller_irsa_role_arn" {
  description = "The ARN of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["aws-alb-ingress-controller"]["enabled"], var.has_aws_lb_controller) ? module.aws-alb-ingress-controller[0].irsa_role_arn : "Not Installed"
}

output "alb_controller_irsa_role_id" {
  description = "The ID of the IAM role used by the AWS Load Balancer Controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["aws-alb-ingress-controller"]["enabled"], var.has_aws_lb_controller) ? module.aws-alb-ingress-controller[0].irsa_role_id : "Not Installed"
}

output "autoscaler_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["cluster-autoscaler"]["enabled"], var.has_autoscaler) ? module.cluster-autoscaler[0].irsa_role_arn : "Not Installed"
}

output "autoscaler_irsa_role_id" {
  description = "The ID of the IAM role used by the Cluster Autoscaler for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["cluster-autoscaler"]["enabled"], var.has_autoscaler) ? module.cluster-autoscaler[0].irsa_role_id : "Not Installed"
}

output "external_dns_irsa_role_arn" {
  description = "The ARN of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["external-dns"]["enabled"], var.has_external_dns) ? module.external-dns[0].irsa_role_arn : "Not Installed"
}

output "external_dns_irsa_role_id" {
  description = "The ID of the IAM role used by the External DNS controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["external-dns"]["enabled"], var.has_external_dns) ? module.external-dns[0].irsa_role_id : "Not Installed"
}

output "external_secrets_irsa_role_arn" {
  description = "The ARN of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["external-secrets"]["enabled"], var.has_external_secrets) ? module.external-secrets[0].irsa_role_arn : "Not Installed"
}

output "external_secrets_irsa_role_id" {
  description = "The ID of the IAM role used by the External Secrets controller for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["external-secrets"]["enabled"], var.has_external_secrets) ? module.external-secrets[0].irsa_role_id : "Not Installed"
}

output "metrics_server_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["metrics-server"]["enabled"], var.has_metrics_server) ? module.metrics-server[0].irsa_role_arn : "Not Installed"
}

output "metrics_server_irsa_role_id" {
  description = "The ID of the IAM role used by the Metrics Server for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["metrics-server"]["enabled"], var.has_metrics_server) ? module.metrics-server[0].irsa_role_id : "Not Installed"
}

output "argocd_irsa_role_arn" {
  description = "The ARN of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["argocd"]["enabled"], var.has_argocd) ? module.argocd[0].irsa_role_arn : "Not Installed"
}

output "argocd_irsa_role_id" {
  description = "The ID of the IAM role used by the ArgoCD for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["argocd"]["enabled"], var.has_argocd) ? module.argocd[0].irsa_role_id : "Not Installed"
}

output "keda_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["keda"]["enabled"], var.has_keda) ? module.keda[0].irsa_role_arn : "Not Installed"
}

output "keda_irsa_role_id" {
  description = "The ID of the IAM role used by the Keda for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["keda"]["enabled"], var.has_keda) ? module.keda[0].irsa_role_id : "Not Installed"
}

output "karpenter_irsa_role_arn" {
  description = "The ARN of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["karpenter"]["enabled"]) ? module.karpenter[0].iam_role_arn : "Not Installed"
}

output "karpenter_irsa_role_id" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["karpenter"]["enabled"]) ? module.karpenter[0].iam_role_name : "Not Installed"
}

output "karpenter_node_iam_role_name" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["karpenter"]["enabled"]) ? module.karpenter[0].node_iam_role_name : "Not Installed"
}

output "karpenter_default_node_class_name" {
  description = "The ID of the IAM role used by the Karpenter for IRSA (IAM Roles for Service Accounts)."
  value       = try(var.services["karpenter"]["enabled"]) ? local.karpenter_default_nodeclass_name : "Not Installed"
}

