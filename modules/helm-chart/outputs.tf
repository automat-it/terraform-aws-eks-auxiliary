output "irsa_role_arn" {
  description = "The ARN of the IAM role for IAM Roles for Service Accounts (IRSA), if created."
  value       = var.irsa_iam_role_name != null ? aws_iam_role.irsa[0].arn : null
}

output "irsa_role_id" {
  description = "The ID of the IAM role for IAM Roles for Service Accounts (IRSA), if created."
  value       = var.irsa_iam_role_name != null ? aws_iam_role.irsa[0].id : null
}
