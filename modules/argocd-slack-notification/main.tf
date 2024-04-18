### Installing helm
resource "helm_release" "argocd-slack-notifications" {
  name             = "argocd-slack-notifications"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  values = [<<EOF
    Chart:
      Name: ${var.chart_name}
    
    argocd:
      secretName: "argocd-notifications-secret"

    awsVaults:
      awsRegion: "${var.aws_region}"
      secretManager:
        awsSecretKeys:
          - '${var.notification_slack_token_secret}'

    serviceAccount:
      name: "${var.service_account_name}"
    EOF
  ]
}