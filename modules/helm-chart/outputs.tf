output "iam_role_arn" {
  description = "The ARN of the IAM role for IAM Roles for Service Accounts if created."
  value       = try(!var.enable_pod_identity && var.iam_openid_provider != null ? aws_iam_role.this[0].arn : null, "")
}

output "iam_role_id" {
  description = "The ID of the IAM role for IAM Roles for Service Accounts if created."
  value       = try(!var.enable_pod_identity && var.iam_openid_provider != null ? aws_iam_role.this[0].id : null, "")
}
