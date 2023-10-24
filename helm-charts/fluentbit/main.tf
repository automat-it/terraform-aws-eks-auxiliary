resource "helm_release" "fluent-bit" {
  name       = var.name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = var.helm_namespace

  version = var.helm_version

  create_namespace  = true
  dependency_update = true

  values = [<<EOF
    image:
      tag: ${var.fluentbit_tag}
    serviceAccount:
      create: true
    service:
      #log_level: off, error, warn, info(default), debug and trace
      extraService: |
        Log_Level    off
    input:
      enabled: false
      parser: cri
      dockerMode: "Off"
    additionalInputs: |
      [INPUT]
          Name              tail
          Tag               kube.*
          Path              /var/log/containers/*.log
          DB                /var/log/flb_kube.db
          multiline.parser  docker,cri
          Docker_Mode       Off
          Skip_Long_Lines   Off
          Refresh_Interval  10
    filter:
      enabled:    true
      mergeLogKey: ""
      keepLog:     Off
    cloudWatch:
      enabled: false
      autoCreateGroup: false
    firehose:
      enabled: false
    kinesis:
      enabled: false
    cloudWatchLogs:
      enabled: false
    elasticsearch:
      enabled: false
    opensearch:
      enabled: true
      match: "*"
      host: ${var.elk_host}
      port: "443"
      awsRegion: ${var.elk_region}
      awsAuth: "Off"
      httpUser: ${var.elk_http_user}
      httpPasswd: ${var.elk_http_password}
      index: "${var.elk_index}"
      logstashFormat: "on"
      logstashPrefix: ${var.elk_logstash_prefix}
      traceOutput: "Off"
      traceError: "Off"
      replaceDots: "On"
    tolerations:
    - operator: "Exists"
    EOF
  ]
}