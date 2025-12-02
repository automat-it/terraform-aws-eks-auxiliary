# Local DNS
locals {
  node_local_dns_helm_values = var.services.local-dns.enabled ? (<<-EOF
    serviceAccount:
      create: true
      name: ${var.services.local-dns.service_account_name}
      annotations:
        %{~if coalesce(var.services.local-dns.iam_role_arn, try(module.node-local-dns[0].iam_role_arn, "no_annotation")) != "no_annotation"~}
        eks.amazonaws.com/role-arn: ${coalesce(var.services.local-dns.iam_role_arn, module.node-local-dns[0].iam_role_arn)}
        %{~endif~}
    image:
      repository: ${var.services.local-dns.image_repository}
      tag: ${var.services.local-dns.image_tag}
    localIP: "${var.services.local-dns.local_ip}"
    clusterDomain: ${var.services.local-dns.cluster_domain}
    upstream:
      clusterIP: "${var.services.local-dns.upstream_cluster_ip}"
      useService: true
      serviceName: ${var.services.local-dns.upstream_service_name}
      namespace: ${var.services.local-dns.upstream_namespace}
      %{~if length(var.services.local-dns.upstream_ips) > 0~}
      ips:
      %{~for ip in var.services.local-dns.upstream_ips~}
        - ${ip}
      %{~endfor~}
      %{~else~}
      ips: []
      %{~endif~}
    cacheTTL: ${var.services.local-dns.cache_ttl}
    zones:
      clusterLocalCacheTTL: ${var.services.local-dns.cluster_local_cache_ttl}
      %{~if length(var.services.local-dns.extra_zones) > 0~}
      extra:
      %{~for zone in var.services.local-dns.extra_zones~}
        - name: "${zone.name}"
          cacheTTL: ${zone.cacheTTL}
      %{~endfor~}
      %{~else~}
      extra: []
      %{~endif~}
    priorityClassName: "system-node-critical"
    corednsConfig:
      enabled: ${var.services.local-dns.coredns_config_enabled}
      name: ${var.services.local-dns.coredns_config_name}
      namespace: ${var.services.local-dns.coredns_config_namespace}
      mountPath: ${var.services.local-dns.coredns_config_mount_path}
  EOF
  ) : ""
}

################################################################################
# Local DNS helm
################################################################################
module "node-local-dns" {
  source = "./modules/helm-chart"
  count  = var.services.local-dns.enabled ? 1 : 0

  name                 = var.services.local-dns.chart_name
  repository           = null
  chart                = "${path.module}/helm-charts/node-local-dns"
  namespace            = var.services.local-dns.namespace
  helm_version         = var.services.local-dns.helm_version
  service_account_name = var.services.local-dns.service_account_name
  create_iam_role      = var.services.local-dns.iam_role_arn == null ? 1 : 0
  iam_role_name        = coalesce(var.services.local-dns.iam_role_name, "${var.cluster_name}-local-dns-iam-role")
  iam_policy_json      = var.services.local-dns.iam_policy_json
  iam_openid_provider  = var.iam_openid_provider

  values = [
    local.node_local_dns_helm_values,
    var.services.local-dns.additional_helm_values
  ]
}
