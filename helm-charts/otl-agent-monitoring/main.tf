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

resource "aws_iam_role_policy_attachment" "irsa_role" {
  role       = aws_iam_role.irsa_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

### opentelemetry-collector agent
resource "helm_release" "agents" {
  name       = "opentelemetry-collector-agents"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = var.namespace

  version = var.helm_version

  create_namespace = true

  dependency_update = true

  values = [<<EOF
    mode: "daemonset"

    presets:
      logsCollection:
        enabled: true
        includeCollectorLogs: true
        storeCheckpoints: true

    config:
      exporters:
        awsemf:
          region: "${var.aws_region}"
          namespace: ContainerInsights
          log_group_name: '/aws/containerinsights/{ClusterName}/performance'
          log_stream_name: 'instanceTelemetry/{NodeName}'
          resource_to_telemetry_conversion:
            enabled: true
          dimension_rollup_option: NoDimensionRollup
          output_destination: cloudwatch
          no_verify_ssl: false
          parse_json_encoded_attr_values: [Sources, kubernetes]
          metric_declarations:
          # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/awscontainerinsightreceiver/README.md
            # *** ALERTS ***
            - dimensions: [[ClusterName]]
              metric_name_selectors:
                - cluster_failed_node_count
            - dimensions: [[ClusterName]]
              metric_name_selectors:
                - node_cpu_utilization
                - node_memory_utilization
                - node_filesystem_utilization
            - dimensions: [[ClusterName]]
              metric_name_selectors:
                - pod_number_of_running_containers
            - dimensions: [[ClusterName], [PodName, Namespace, ClusterName]]
              metric_name_selectors:
                - number_of_container_restarts
            %{~if var.collect_minimal_statistic~}
            # *** MINIMAL STATISTIC ***
            - dimensions: [[ClusterName, NodeName, InstanceId]]
              metric_name_selectors:
                - node_cpu_utilization
                - node_memory_utilization
                - node_diskio_io_serviced_total
                - node_diskio_io_service_bytes_total
                - node_filesystem_utilization
            - dimensions: [[ClusterName, Namespace, PodName]]
              metric_name_selectors:
                - pod_cpu_usage_total
                - pod_cpu_request
                - pod_cpu_limit
                - pod_memory_limit
                - pod_memory_request
                - pod_memory_usage
            %{~endif~}           
        logging:
          loglevel: info
      processors:
        batch/metrics:
          timeout: ${var.k8s_metrics_batch_interval}
      receivers:
        jaeger:
          protocols:
            grpc:
              endpoint: $${MY_POD_IP}:14250
            thrift_http:
              endpoint: $${MY_POD_IP}:14268
            thrift_compact:
              endpoint: $${MY_POD_IP}:6831
        otlp:
          protocols:
            grpc:
              endpoint: $${MY_POD_IP}:4317
            http:
              endpoint: $${MY_POD_IP}:4318
        prometheus:
          config:
            scrape_configs:
              - job_name: opentelemetry-collector
                scrape_interval: 10s
                static_configs:
                  - targets:
                      - $${MY_POD_IP}:8888
        zipkin:
          endpoint: $${MY_POD_IP}:9411
        awscontainerinsightreceiver:
          collection_interval: ${var.k8s_metrics_interval}
          container_orchestrator: eks
          add_service_as_attribute: true 
          prefer_full_pod_name: false 
          add_full_pod_name_metric_label: false
      service:
        pipelines:
          metrics:
            receivers: [awscontainerinsightreceiver]
            processors: [batch/metrics]
            exporters: [awsemf]

    serviceAccount:
      create: true
      annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.irsa_role.arn}
      name: "${var.service_account_name}"

    clusterRole:
      create: true
      annotations: {}
      name: "otel-role"
      rules:
        - apiGroups: ['*']
          resources: ['*']
          verbs: ['*']
        - apiGroups:
          - "*"
          resources:
          - events
          - namespaces
          - namespaces/status
          - nodes
          - nodes/spec
          - pods
          - pods/status
          - replicationcontrollers
          - replicationcontrollers/status
          - resourcequotas
          - services
          - endpoints
          - nodes/proxy
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - apps
          resources:
          - daemonsets
          - deployments
          - replicasets
          - statefulsets
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - extensions
          resources:
          - daemonsets
          - deployments
          - replicasets
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - batch
          resources:
          - jobs
          - cronjobs
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - "*"
          resources:
          - horizontalpodautoscalers
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - "*"
          resources:
          - nodes/stats
          - configmaps
          - events
          - leases
          verbs:
          - get
          - list
          - watch
          - create
          - update

      clusterRoleBinding:
        annotations: {}
        name: "otel-role"

    nodeSelector: {}
    tolerations: 
      - key: dedicated
        operator: Equal
        value: ${var.toleration_pool}
        effect: NoSchedule
    affinity: {}
    topologySpreadConstraints: []

    extraEnvs:
    - name: KUBE_NODE_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: spec.nodeName
    - name: K8S_NODE_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: spec.nodeName
    - name: HOST_IP
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    - name: K8S_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: HOST_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: K8S_NAMESPACE
      valueFrom:
          fieldRef:
            fieldPath: metadata.namespace

    resources:
      limits:
        cpu: 256m
        memory: 1024Mi
      requests:
        cpu: 50m
        memory: 512Mi

    hostNetwork: true

    extraVolumes:
      - name: varlog
        hostPath:
          path: /var/log
          type: ''
      - name: rootfs
        hostPath:
          path: /
      - name: varlibdocker
        hostPath:
          path: /var/lib/docker
      - name: containerdsock
        hostPath:
          path: /run/containerd/containerd.sock
      - name: sys
        hostPath:
          path: /sys
      - name: devdisk
        hostPath:
          path: /dev/disk/
    extraVolumeMounts:
      - name: varlog
        readOnly: true
        mountPath: /var/log
      - name: rootfs
        mountPath: /rootfs
        readOnly: true
      - name: containerdsock
        mountPath: /run/containerd/containerd.sock
        readOnly: true
      - name: sys
        mountPath: /sys
        readOnly: true
      - name: devdisk
        mountPath: /dev/disk
        readOnly: true
    EOF
  ]
}

### opentelemetry-collector deployment
## Getting kubernetes events
locals {
  eks_event_log_group        = "/aws/containerinsights/${var.eks_cluster_name}/events"
  eks_event_log_group_stream = "${var.eks_cluster_name}-stream"
  eks_event_metric_name      = "${var.eks_cluster_name}-${var.k8s_ns_events_severity}EventCount"
}
resource "aws_cloudwatch_log_group" "events" {
  name              = local.eks_event_log_group
  retention_in_days = var.k8s_ns_events_retention_days
}

resource "aws_cloudwatch_log_metric_filter" "events" {
  name           = "EventCount"
  pattern        = "{ $.body.type != \"DELETED\" }"
  log_group_name = local.eks_event_log_group

  metric_transformation {
    name          = local.eks_event_metric_name
    namespace     = "ContainerInsights"
    value         = "1"
    default_value = "0"
  }

  depends_on = [
    aws_cloudwatch_log_group.events
  ]
}
resource "helm_release" "deployment" {
  name       = "opentelemetry-collector-deployment"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = var.namespace

  version = var.helm_version

  create_namespace = true

  dependency_update = true

  values = [<<EOF
    mode: "deployment"

    replicaCount: 1

    presets:
      kubernetesEvents:
        enabled: false

    config:
      exporters:
        awscloudwatchlogs:
          log_group_name: "${local.eks_event_log_group}"
          log_stream_name: "${local.eks_event_log_group_stream}"
          region: "${var.aws_region}"
          log_retention: "${var.k8s_ns_events_retention_days}"
          sending_queue:
            queue_size: 50
          retry_on_failure:
            enabled: true
            initial_interval: 10ms
      receivers:
        k8sobjects:
          objects:
            - name: events
              mode: watch
              field_selector: type=${var.k8s_ns_events_severity}
              group: events.k8s.io
              namespaces: [${var.k8s_ns_events_to_collect}]

      service:
        pipelines:
          logs:
            receivers: [k8sobjects]
            exporters: [awscloudwatchlogs]

    serviceAccount:
      create: false
      name: "${var.service_account_name}"

    clusterRole:
      create: false
      name: "otel-role"

    nodeSelector:
      pool: ${var.toleration_pool}
    tolerations: 
      - key: dedicated
        operator: Equal
        value: ${var.toleration_pool}
        effect: NoSchedule
    affinity: {}
    topologySpreadConstraints: []

    ports:
      otlp:
        enabled: false
      otlp-http:
        enabled: true
        containerPort: 4318
        servicePort: 4318
        hostPort: 8318
        protocol: TCP
      jaeger-compact:
        enabled: false
      jaeger-thrift:
        enabled: false
      jaeger-grpc:
        enabled: false
      zipkin:
        enabled: false
      metrics:
        enabled: false
    
    resources:
      requests:
        cpu: 50m
        memory: 50Mi
      limits:
        cpu: 256m
        memory: 512Mi
    EOF
  ]
  depends_on = [
    helm_release.agents,
    aws_cloudwatch_log_group.events
  ]
}

# vim:filetype=terraform ts=2 sw=2 et:
