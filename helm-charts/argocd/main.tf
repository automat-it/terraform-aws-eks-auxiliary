### Variables
variable "chart_version" { default = "5.12.2" }
variable "chart_name" { default = "argo-cd" }
variable "namespace" { default = "argocd" }
variable "pool" { default = "system" }
variable "iam_openid_provider_url" { type = string }
variable "iam_openid_provider_arn" { type = string }
variable "service_account_name" {
  type    = string
  default = "argocd-sa"
}
variable "aws_region" {
  default = "us-east-1"
}
variable "irsa_iam_role_name" { type = string }
variable "domain_zone" { type = string }
variable "ingress" {
  default = ""
}

### Notifications
variable "notification_slack_token_secret" {
  default     = ""
  description = "AWS Secret manager key to keep a slack token"
}

### Secrets
variable "extra_secrets_aws_secret" {
  default     = ""
  description = "AWS Secret manager key to keep map of secrets that are merged into argocd-secret"
}

### Backup ###
variable "enable_backup" {
  default     = false
  description = "Enable backup for the ArgoCD"
}

variable "backup_cron" {
  type        = string
  default     = "0 1 * * *"
  description = "Backup job run period in crontab format. Default run is daily 1 AM"
}
variable "destination_s3_name" {
  type    = string
  default = ""
}

variable "destination_s3_name_prefix" {
  type    = string
  default = "argocd"
}


###  OIDC
data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.iam_openid_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    principals {
      identifiers = [var.iam_openid_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "irsa_role" {
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  name               = var.irsa_iam_role_name
}

### ArgoCD helm
locals {
  argocd_url         = "https://argocd.${var.domain_zone}"
  enableExtraObjects = var.extra_secrets_aws_secret != "" || var.notification_slack_token_secret != "" ? true : false
  extraObjects       = <<EOF
  - apiVersion: external-secrets.io/v1beta1
    kind: SecretStore
    metadata:
      name: ${var.chart_name}-secret-store-aws-secrets
      namespace: ${var.namespace}
    spec:
      provider:
        aws:
          auth:
            jwt:
              serviceAccountRef:
                name: ${var.service_account_name}
                namespace: ${var.namespace}
          region: ${var.aws_region}
          service: SecretsManager
  %{~if var.extra_secrets_aws_secret != ""~}
  - apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: ${var.chart_name}-ext-aws-secret-slack
      namespace: ${var.namespace}
    spec:
      refreshInterval: "5s"
      secretStoreRef:
        name: ${var.chart_name}-secret-store-aws-secrets
        kind: SecretStore
      target:
        name: "argocd-secret"
        creationPolicy: Orphan
        deletionPolicy: Merge
        template:
          mergePolicy: Merge
          engineVersion: v2
      dataFrom:
      - extract:
          key: "${var.extra_secrets_aws_secret}"
  %{~endif~}
  %{~if var.notification_slack_token_secret != ""~}
  - apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: ${var.chart_name}-ext-aws-secret-slack
      namespace: ${var.namespace}
    spec:
      refreshInterval: "5s"
      secretStoreRef:
        name: ${var.chart_name}-secret-store-aws-secrets
        kind: SecretStore
      target:
        name: "argocd-notifications-secret"
        creationPolicy: Orphan
        deletionPolicy: Merge
        template:
          mergePolicy: Merge
          engineVersion: v2
      dataFrom:
      - extract:
          key: "${var.notification_slack_token_secret}"
  %{~endif~}
  EOF
}

resource "helm_release" "argo-cd" {
  name              = var.chart_name
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  namespace         = var.namespace
  create_namespace  = true
  version           = var.chart_version
  dependency_update = true
  # skip_crds    = true
  force_update = true
  values = [<<EOF
    nodeSelector:
      pool: ${var.pool}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.pool}
        effect: NoSchedule
    controller:
      args:
        appResyncPeriod: "60"
      serviceAccount:
        create: false
        name: ${var.service_account_name}
    server:
      podAnnotations:
        tftimestamp: ${timestamp()}
      serviceAccount:
        name: ${var.service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
      %{~if var.ingress != ""~}
      ingress:
      ${indent(6, var.ingress)}
      %{~endif~}
      config:
        statusbadge.enabled: "true"
        exec.enabled: "true"
        url: ${local.argocd_url}
      service:
        type: NodePort
    %{~if local.enableExtraObjects == true~}
    extraObjects:
    ${indent(4, local.extraObjects)}
    %{~endif~}
    notifications:
      enabled: true
      argocdUrl: ${local.argocd_url}
      secret:
        create: true
      cm:
        create: true
      notifiers:
        service.slack: |
          token: $slack-token
      templates:
        template.app-sync-status-unknown: |
          email:
            subject: Application {{.app.metadata.name}} sync status is 'Unknown'
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} sync is 'Unknown'.
            Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
            {{if ne .serviceType "slack"}}
            {{range $c := .app.status.conditions}}
                * {{$c.message}}
            {{end}}
            {{end}}
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#E96D76",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $image := .app.status.summary.images}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "Image {{add $index 1}}",
                  "value": "{{$image}}"
                }
                {{end}}
                ]
              }]
        template.app-sync-failed: |
          email:
            subject: Failed to sync application {{.app.metadata.name}}.
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}}  The sync operation of application {{.app.metadata.name}} has failed at {{.app.status.operationState.finishedAt}} with the following error: {{.app.status.operationState.message}}
            Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#E96D76",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-health-degraded: |
          email:
            subject: Application {{.app.metadata.name}} has degraded.
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} has degraded.
            Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#f4c030",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-deployed: |
          email:
            subject: New version of an application {{.app.metadata.name}} is up and running.
          message: |
            {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} is now running new version of deployments manifests.
          slack:
            attachments: |
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#18be52",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                },
                {
                  "title": "Revision",
                  "value": "{{.app.status.sync.revision}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]

      triggers:
        trigger.on-deployed: |
          - description: Application is synced and healthy. Triggered once per commit.
            oncePer: app.status.operationState.syncResult.revision
            send:
            - app-deployed
            when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy' and app.status.sync.status == 'Synced' and time.Now().Sub(time.Parse(app.status.operationState.startedAt)).Seconds() >= 30
        trigger.on-health-degraded: |
          - description: Application has degraded
            send:
            - app-health-degraded
            when: app.status.health.status == 'Degraded'
        trigger.on-sync-failed: |
          - description: Application syncing has failed
            send:
            - app-sync-failed
            when: app.status.operationState.phase in ['Error', 'Failed']
        trigger.on-sync-status-unknown: |
          - description: Application status is 'Unknown'
            send:
            - app-sync-status-unknown
            when: app.status.sync.status == 'Unknown'
        defaultTriggers: |
          - on-sync-status-unknown
EOF
  ]
}

### Backup
module "argocd" {
  count = var.enable_backup ? 1 : 0

  source = "./argocd-s3-backup"

  chart_name           = var.chart_name
  namespace            = var.namespace
  chart_version        = var.chart_version
  service_account_name = var.service_account_name

  backup_cron                = var.backup_cron
  destination_s3_name        = var.destination_s3_name
  destination_s3_name_prefix = var.destination_s3_name_prefix

  depends_on = [
    helm_release.argo-cd
  ]
}

output "irsa_role_name" {
  value = aws_iam_role.irsa_role.name
}
# vim:filetype=terraform ts=2 sw=2 et:
