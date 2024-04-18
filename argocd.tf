### ArgoCD helm
locals {
  argocd_url = "https://argocd.${var.domain_zone}"
  # Helm versions
  argocd_helm_version = "6.7.12"
  # K8s namespace to deploy
  argocd_namespace = try(kubernetes_namespace_v1.argocd[0].id, "")
  # K8S Service Account Name
  argocd_service_account_name = "argocd-sa"
  argocd_irsa_iam_role_name   = "${var.cluster_name}-argo-cd"
  argocd_ingress              = var.argocd_custom_ingress != "" ? var.argocd_custom_ingress : local.argocd_default_ingress
  argocd_default_ingress      = <<EOF
  enabled: true
  hosts:
    - "argocd.${var.domain_zone}"
  rules:
    - https:
        paths:
          - backend:
              serviceName: ssl-redirect
              servicePort: use-annotation
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: "${lower(var.basename)}-argocd-alb"
    alb.ingress.kubernetes.io/group.name: "internal"
    alb.ingress.kubernetes.io/ip-address-type: ipv4
    alb.ingress.kubernetes.io/scheme: "internal"
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/tags: 'Environment=${var.project_env}, Managed_by=helm, Project=${var.project_name}'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  EOF
  argocd_irsa_policy_json     = null
  argocd_helm_values = [<<EOF
    nodeSelector:
      pool: system
    tolerations:
      - key: dedicated
        operator: Equal
        value: system
        effect: NoSchedule
    controller:
      args:
        appResyncPeriod: "60"
      serviceAccount:
        create: false
        name: ${local.argocd_service_account_name}
    server:
      serviceAccount:
        name: ${local.argocd_service_account_name}
        annotations:
          eks.amazonaws.com/role-arn: ${try(module.argocd[0].irsa_role_arn, "")}
      ingress:
      ${indent(6, local.argocd_ingress)}
      config:
        statusbadge.enabled: "true"
        exec.enabled: "true"
        url: ${local.argocd_url}
      service:
        type: NodePort
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
            when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy' and app.status.sync.status == 'Synced'
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

module "argocd" {
  source                  = "./modules/helm-chart"
  count                   = var.has_argocd ? 1 : 0
  name                    = "argocd"
  repository              = "https://argoproj.github.io/argo-helm"
  chart                   = "argo-cd"
  namespace               = local.argocd_namespace
  helm_version            = local.argocd_helm_version
  service_account_name    = local.argocd_service_account_name
  irsa_iam_role_name      = local.argocd_irsa_iam_role_name
  irsa_policy_json        = local.argocd_irsa_policy_json
  iam_openid_provider_url = var.iam_openid_provider_url
  iam_openid_provider_arn = var.iam_openid_provider_arn
  values                  = local.argocd_helm_values

  depends_on = [
    kubernetes_namespace_v1.general,
    module.aws-alb-ingress-controller
    ]
  
}

### Notifications
### Merging slack token from AWS Secret
module "slack-notifications" {
  count = var.notification_slack_token_secret != "" ? 1 : 0

  source = "./modules/argocd-slack-notification"

  notification_slack_token_secret = var.notification_slack_token_secret

  chart_name           = "argo-cd"
  namespace            = local.argocd_namespace
  chart_version        = local.argocd_helm_version
  service_account_name = local.argocd_service_account_name
  aws_region           = var.aws_region

  depends_on = [
    module.argocd
  ]

}
### Backup
module "argocd-backup" {
  count = var.enable_backup ? 1 : 0

  source = "./modules/argocd-s3-backup"

  chart_name           = "argo-cd"
  namespace            = local.argocd_namespace
  chart_version        = local.argocd_helm_version
  service_account_name = local.argocd_service_account_name

  backup_cron                = var.backup_cron
  destination_s3_name        = var.destination_s3_name
  destination_s3_name_prefix = var.destination_s3_name_prefix

  depends_on = [
    module.argocd
  ]
}
