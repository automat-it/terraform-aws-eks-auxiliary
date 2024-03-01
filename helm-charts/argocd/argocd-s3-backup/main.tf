### Installing helm
resource "helm_release" "argocd-backup" {
  name      = "argocd-backup"
  chart     = "${path.module}/chart"
  namespace = var.namespace
  values = [<<EOF
    containerMain:
      image: quay.io/argoproj/argocd:v2.5.0
    aws:
      s3:
        name: "${var.destination_s3_name}"
        prefix: "${var.destination_s3_name_prefix}"
    cronJobsSchedule:
      period: "${var.backup_cron}"
    
    serviceAccount:
      name: "${var.service_account_name}"
    EOF
  ]
}