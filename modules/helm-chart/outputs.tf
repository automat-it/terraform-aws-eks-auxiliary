output "irsa_role_arn" {
  description = "The ARN of the IAM role for IAM Roles for Service Accounts (IRSA), if created."
  value       = try(!var.enable_pod_identity && var.iam_openid_provider != null ? aws_iam_role.irsa[0].arn : null, "")
}

output "irsa_role_id" {
  description = "The ID of the IAM role for IAM Roles for Service Accounts (IRSA), if created."
  value       = try(!var.enable_pod_identity && var.iam_openid_provider != null ? aws_iam_role.irsa[0].id : null, "")
}
