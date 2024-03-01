## How to Contribute

To add a component to the cluster module, follow these steps:

1. Place the component file in the root directory, e.g. [external-dns.tf](external-dns.tf).
2. Ensure that any required variables for the new component are added to the variables.tf file, like:
```terraform
variable "has_external_dns" { default = false }
```
3. Thoroughly test your changes to ensure proper functionality.
4. Once you've completed testing, submit a pull request with your changes for review and integration.
