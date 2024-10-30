### ArgoCD helm
locals {
  # Helm override values
  argocd_default_ingress = <<EOF
  server:
    ingress:
      enabled: true
      controller: aws
      ingressClassName: alb
      aws:
        serviceType: ClusterIP
        backendProtocolVersion: GRPC
      annotations:
        %{~if coalesce(var.services.argocd.load_balancer_name, "no_name") != "no_name"~}
        alb.ingress.kubernetes.io/load-balancer-name: ${var.services.argocd.load_balancer_name}
        %{~endif~}
        alb.ingress.kubernetes.io/group.name: ${var.services.argocd.load_balancer_group_name}
        alb.ingress.kubernetes.io/ip-address-type: ipv4
        alb.ingress.kubernetes.io/scheme: ${var.services.argocd.load_balancer_scheme}
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-port: traffic-port
        alb.ingress.kubernetes.io/backend-protocol: HTTP
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
        alb.ingress.kubernetes.io/ssl-redirect: '443'
  configs:
    params:
      server.insecure: true
  EOF
  argocd_helm_values     = <<EOF
  global:
    domain: ${coalesce(var.services.argocd.argocd_url, "argocd.${var.domain_zone}")}
    %{~if coalesce(var.services.argocd.nodepool, "no_pool") != "no_pool"~}
    nodeSelector:
      pool: ${var.services.argocd.nodepool}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${var.services.argocd.nodepool}
        effect: NoSchedule
    %{~endif~}
  server:
    serviceAccount:
      name: ${var.services.argocd.service_account_name}
      %{~if coalesce(var.services.argocd.irsa_role_arn, try(module.argocd[0].irsa_role_arn, "no_iam_role")) != "no_iam_role"~}
      annotations:
        eks.amazonaws.com/role-arn: ${coalesce(var.services.argocd.irsa_role_arn, module.argocd[0].irsa_role_arn)}
      %{~endif~}
  controller:
    serviceAccount:
      create: false
      name: ${var.services.argocd.service_account_name}
  configs:
    cm:
      exec.enabled: "true"
      timeout.reconciliation: 60s
  EOF
  argocd_notifications   = <<EOF
  %{~if coalesce(var.services.argocd.notification_slack_token_secret, "no_slack_notification") != "no_slack_notification"~}
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
  extraObjects:
    - apiVersion: external-secrets.io/v1beta1
      kind: SecretStore
      metadata:
        name: argocd-secret-store-aws-secret
      spec:
        provider:
          aws:
            auth:
              jwt:
                serviceAccountRef:
                  name: ${var.services.argocd.service_account_name}
            region: ${var.aws_region}
            service: SecretsManager
    - apiVersion: external-secrets.io/v1beta1
      kind: ExternalSecret
      metadata:
        name: argocd-ext-aws-secret-slack
      spec:
        refreshInterval: "5s"
        secretStoreRef:
          name: argocd-secret-store-aws-secret
          kind: SecretStore
        target:
          name: argocd-notifications-secret
          creationPolicy: Merge
          deletionPolicy: Merge
          template:
            mergePolicy: Merge
            engineVersion: v2
        dataFrom:
          - extract:
              key: ${var.services.argocd.notification_slack_token_secret}
  %{~endif~}
  EOF
}

################################################################################
# Argocd helm
################################################################################
module "argocd" {
  source               = "./modules/helm-chart"
  count                = var.services.argocd.enabled ? 1 : 0
  name                 = "argocd"
  repository           = "https://argoproj.github.io/argo-helm"
  chart                = "argo-cd"
  namespace            = var.services.argocd.namespace
  helm_version         = var.services.argocd.helm_version
  service_account_name = var.services.argocd.service_account_name
  irsa_iam_role_name   = var.services.argocd.irsa_iam_role_name
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.argocd_helm_values,
    coalesce(var.services.argocd.custom_ingress, local.argocd_default_ingress),
    coalesce(var.services.argocd.custom_notifications, local.argocd_notifications),
    var.services.argocd.additional_helm_values
  ]

  depends_on = [
    kubernetes_namespace_v1.general,
    module.aws-alb-ingress-controller
  ]
}
