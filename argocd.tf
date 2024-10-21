### ArgoCD helm
locals {
  argocd_enabled = try(var.services.argocd.enabled, var.has_argocd)
  argocd_url     = try(var.services.argocd.argocd_url, "argocd.${var.domain_zone}")
  # Helm versions
  argocd_helm_version = try(var.services.argocd.helm_version, "7.3.11")
  # K8s namespace to deploy
  argocd_namespace = try(var.services.argocd.namespace, try(kubernetes_namespace_v1.argocd[0].id, "argocd"))
  # K8S Service Account
  argocd_service_account_name = try(var.services.argocd.service_account_name, "argocd-sa")
  argocd_irsa_iam_role_name   = try(var.services.argocd.irsa_iam_role_name, "${local.lower_cluster_name}-argo-cd")
  argocd_ingress              = try(var.services.argocd.custom_ingress, var.argocd_custom_ingress) != "" ? try(var.services.argocd.custom_ingress, var.argocd_custom_ingress) : local.argocd_default_ingress
  argocd_default_ingress      = <<EOF
  server:
    ingress:
      enabled: true
      controller: aws
      ingressClassName: alb
      aws:
        serviceType: ClusterIP
        backendProtocolVersion: GRPC
      annotations:
        alb.ingress.kubernetes.io/load-balancer-name: ${local.lower_cluster_name}-argocd-alb
        alb.ingress.kubernetes.io/group.name: internal
        alb.ingress.kubernetes.io/ip-address-type: ipv4
        alb.ingress.kubernetes.io/scheme: internal
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-port: traffic-port
        alb.ingress.kubernetes.io/success-codes: 200-399
        alb.ingress.kubernetes.io/backend-protocol: HTTP
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
        alb.ingress.kubernetes.io/tags: 'Environment=${var.project_env}, Managed_by=helm, Project=${var.project_name}'
        alb.ingress.kubernetes.io/ssl-redirect: '443'
  EOF
  argocd_helm_values          = <<EOF
    controller:
      serviceAccount:
        create: false
        name: ${local.argocd_service_account_name}
    global:
      domain: ${local.argocd_url}
      %{~ if try(var.services.argocd.nodepool, var.cluster_nodepool_name) != "" ~}
      nodeSelector:
        pool: ${try(var.services.argocd.nodepool, var.cluster_nodepool_name)}
      tolerations:
        - key: dedicated
          operator: Equal
          value: ${try(var.services.argocd.nodepool, var.cluster_nodepool_name)}
          effect: NoSchedule
      %{~ endif ~}
    server:
      serviceAccount:
        name: ${local.argocd_service_account_name}
        %{~ if try(var.services.argocd.irsa_role_arn, try(module.argocd[0].irsa_role_arn, "")) != "" ~}
        annotations:
          eks.amazonaws.com/role-arn: ${try(var.services.argocd.irsa_role_arn, module.argocd[0].irsa_role_arn)}
        %{~ endif ~}
    configs:
      cm:
        exec.enabled: "true"
        timeout.reconciliation: 60s
    notifications:
      enabled: true
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
}

module "argocd" {
  source               = "./modules/helm-chart"
  count                = local.argocd_enabled ? 1 : 0
  name                 = "argocd"
  repository           = "https://argoproj.github.io/argo-helm"
  chart                = "argo-cd"
  namespace            = local.argocd_namespace
  helm_version         = local.argocd_helm_version
  service_account_name = local.argocd_service_account_name
  irsa_iam_role_name   = local.argocd_irsa_iam_role_name
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.argocd_helm_values,
    local.argocd_ingress,
    try(var.services.argocd.additional_helm_values, null),
  ]

  depends_on = [
    kubernetes_namespace_v1.general,
    module.aws-alb-ingress-controller
  ]
}

### Notifications
### Merging slack token from AWS Secret
module "slack-notifications" {
  count = try(var.services.argocd.notification_slack_token_secret, var.notification_slack_token_secret) != "" && local.argocd_enabled ? 1 : 0

  source = "./modules/argocd-slack-notification"

  notification_slack_token_secret = try(var.services.argocd.notification_slack_token_secret, var.notification_slack_token_secret)

  chart_name           = "argo-cd"
  namespace            = local.argocd_namespace
  chart_version        = local.argocd_helm_version
  service_account_name = local.argocd_service_account_name
  aws_region           = var.aws_region

  depends_on = [module.argocd]
}
