## How to Contribute

To add a service to the module, follow these steps:

1. Place the component file for new service in the root directory, e.g. [external-dns.tf](external-dns.tf).
2. Ensure that any required variables for the new component are added to the services variable in [variables.tf](variables.tf?plain=1#L70) file, like:
```hcl
variable "services" {
  type = object({
    new_service = optional(object({
      enabled                = bool
      helm_version           = optional(string, "version")
      namespace              = optional(string, "namespace")
      nodepool               = optional(string, "nodepool")
      additional_helm_values = optional(string, "")
      }), { enabled = false }),
  })
}
```
3. Add outputs for new service to [outputs.tf](outputs.tf) file, like:
```hcl
output "new_service_iam_role_arn" {
  description = "The ARN of the IAM role used by the New service (IAM Roles for Service Accounts)."
  value       = var.services.new_service.enabled ? module.new_service[0].iam_role_arn : null
}

output "new_service_iam_role_id" {
  description = "The ID of the IAM role used by the New service (IAM Roles for Service Accounts)."
  value       = var.services.new_service.enabled ? module.new_service[0].iam_role_id : null
}
```
4. Thoroughly test your changes to ensure proper functionality.
5. Once you've completed testing, submit a pull request with your changes for review and integration.

## Provider Versions

Main branch is following Terraform AWS 6.x Provider Version, and latest version of EKS.
To work with 5.x terraform provider version please checkout on - `main-terraform-aws-v5-provider`
