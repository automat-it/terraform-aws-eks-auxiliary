### Variables
variable "helm_version" { default = "3.8.2" }
variable "namespace" { default = "general" }

### Metrics-server helm
resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"

  version = var.helm_version

  namespace = var.namespace

  dependency_update = true

  values = [<<EOF
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    EOF
  ]
}

# vim:filetype=terraform ts=2 sw=2 et: