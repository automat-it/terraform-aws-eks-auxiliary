# Karpenter
locals {
  # Helm override values
  karpenter_helm_values = !var.services.karpenter.enabled ? "" : <<-EOT
    serviceAccount:
      %{~if try(module.karpenter[0].service_account, "") != ""~}
      name: ${module.karpenter[0].service_account}
      %{~endif~}
      annotations:
      %{~if coalesce(module.karpenter[0].iam_role_arn, "not_karpenter_iam") != "not_karpenter_iam"~}
        eks.amazonaws.com/role-arn: ${module.karpenter[0].iam_role_arn}
        %{~else~}
        eks.amazonaws.com/role-arn: ${var.services.karpenter.irsa_iam_role_arn}
      %{~endif~}
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      %{~if try(module.karpenter[0].queue_name, "") != ""~}
      interruptionQueue: ${module.karpenter[0].queue_name}
      %{~endif~}
    %{~if coalesce(var.services.karpenter.node_selector, {}) != {} ~}
    nodeSelector:
    %{~for key, value in var.services.karpenter.node_selector~}
      ${key}: ${value}
    %{~endfor~}
    %{~endif~}
    %{~if coalesce(var.services.karpenter.node_selector, {}) != {} || coalesce(var.services.karpenter.additional_tolerations, []) != []~}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    %{~for key, value in var.services.karpenter.node_selector~}
      - key: dedicated
        operator: Equal
        value: ${value}
        effect: NoSchedule
    %{~endfor~}
    %{~if var.services.karpenter.additional_tolerations != null~}
    %{~for i in var.services.karpenter.additional_tolerations~}
      - key: ${i.key}
        operator: ${i.operator}
        value: ${i.value}
        effect: ${i.effect}
        %{~if i.tolerationSeconds != null~}
        tolerationSeconds: ${i.tolerationSeconds}
        %{~endif~}
    %{~endfor~}
    %{~endif~}
    %{~else~}
    tolerations: []
    %{~endif~}
    EOT

  # Default karpenter nodeclass
  default_nodeclass_yaml = !var.services.karpenter.enabled ? "" : <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: ${var.services.karpenter.default_nodeclass_name}
    spec:
      kubelet:
        %{~if var.services.local-dns.enabled~}
        clusterDNS:
          - "${var.services.local-dns.local_ip}"
          - "${var.services.local-dns.upstream_cluster_ip}"
        %{~endif~}
        %{~if try(var.services.karpenter.default_nodeclass_pods_per_core, null) != null ~}
        podsPerCore: ${var.services.karpenter.default_nodeclass_pods_per_core}
        %{~endif~}
        %{~if try(var.services.karpenter.default_nodeclass_max_pods, null) != null ~}
        maxPods: ${var.services.karpenter.default_nodeclass_max_pods}
        %{~endif~}
    %{~if coalesce(var.services.karpenter.default_nodeclass_ami_family, "no_nodeclass") != "no_nodeclass"~}
      amiFamily: ${var.services.karpenter.default_nodeclass_ami_family}
    %{~endif~}
      amiSelectorTerms:
        - alias: ${var.services.karpenter.default_nodeclass_ami_alias}
      %{~if coalesce(module.karpenter[0].node_iam_role_name, "no_iam") != "no_iam"~}
      role: ${module.karpenter[0].node_iam_role_name}
      %{~endif~}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - id: ${var.services.karpenter.node_security_group_id}
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
            kubernetes.io/cluster/${var.cluster_name}: owned
            "aws:eks:cluster-name": ${var.cluster_name}
      metadataOptions:
        httpPutResponseHopLimit: ${var.services.karpenter.http_put_response_hop_limit}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: ${var.services.karpenter.default_nodeclass_volume_size}
            volumeType: ${var.services.karpenter.default_nodeclass_volume_type}
            encrypted: true
            deleteOnTermination: true
      tags: ${jsonencode(merge(
  {
    "karpenter.sh/discovery" = var.cluster_name,
    "Name"                   = "${var.cluster_name}-Karpenter-worker"
  },
  var.node_class_additional_tags
))}
  YAML

# Default karpenter nodepool
default_nodepool_yaml = !var.services.karpenter.enabled ? "" : <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          expireAfter: Never
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ${jsonencode(var.services.karpenter.default_nodeclass_instance_category)}
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ${jsonencode(var.services.karpenter.default_nodeclass_instance_cpu)}
    %{if length(var.services.karpenter.default_nodeclass_instance_cpu_manufacturer) > 0}
            - key: "karpenter.k8s.aws/instance-cpu-manufacturer"
              operator: In
              values: ${jsonencode(var.services.karpenter.default_nodeclass_instance_cpu_manufacturer)}
    %{endif}
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
    %{if length(var.services.karpenter.default_nodeclass_instance_generation) > 0}
              operator: In
              values: ${jsonencode(var.services.karpenter.default_nodeclass_instance_generation)}
    %{else}
              operator: Gt
              values: ["2"]
    %{endif}
            - key: "karpenter.sh/capacity-type"
              operator: In
              values:  ${jsonencode(var.services.karpenter.default_nodepool_capacity_type)}
      limits:
        cpu: ${var.services.karpenter.default_nodepool_cpu_limit}
      disruption:
  %{if coalesce(var.services.karpenter.consolidation_policy, "default") != "default"~}
        consolidationPolicy: ${var.services.karpenter.consolidation_policy}
  %{endif}
        consolidateAfter: 30s
  %{if var.services.karpenter.enable_budgets}
        budgets: ${jsonencode(var.services.karpenter.budgets)}
  %{endif}
  YAML

node_pools = var.services.karpenter.enabled && var.services.karpenter.deploy_default_nodepool ? merge({ default = coalesce(var.services.karpenter.default_nodepool_yaml, local.default_nodepool_yaml) }, var.services.karpenter.additional_nodepools_yaml) : var.services.karpenter.additional_nodepools_yaml
}

################################################################################
# Karpenter helm
################################################################################
module "karpenter-helm" {
  source       = "./modules/helm-chart"
  count        = var.services.karpenter.enabled ? 1 : 0
  name         = var.services.karpenter.chart_name
  repository   = "oci://public.ecr.aws/karpenter"
  chart        = "karpenter"
  namespace    = var.services.karpenter.namespace
  helm_version = var.services.karpenter.helm_version
  skip_crds    = var.services.karpenter.manage_crd

  values = [
    local.karpenter_helm_values,
    var.services.karpenter.additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}

################################################################################
# Karpenter crd helm
################################################################################
module "karpenter-crd-helm" {
  source       = "./modules/helm-chart"
  count        = var.services.karpenter.manage_crd && var.services.karpenter.enabled ? 1 : 0
  name         = var.services.karpenter.chart_crd_name
  repository   = "oci://public.ecr.aws/karpenter"
  chart        = "karpenter-crd"
  namespace    = var.services.karpenter.namespace
  helm_version = var.services.karpenter.helm_version

  values = [
    local.karpenter_helm_values,
    var.services.karpenter.crd_additional_helm_values
  ]

  depends_on = [kubernetes_namespace_v1.general]
}

################################################################################
# Karpenter external module
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.26.1"

  count = var.services.karpenter.enabled ? 1 : 0

  cluster_name = var.cluster_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  # IAM
  create_iam_role          = var.services.karpenter.create_irsa_iam_role
  iam_role_name            = coalesce(var.services.karpenter.irsa_iam_role_name, "${var.cluster_name}-Karpenter-Role")
  iam_role_policies        = var.services.karpenter.irsa_iam_role_additional_policies
  iam_role_use_name_prefix = false
  iam_role_tags            = var.tags

  create_node_iam_role          = var.services.karpenter.create_node_iam_role
  node_iam_role_name            = coalesce(var.services.karpenter.node_iam_role_name, "${var.cluster_name}-Karpenter-Node-Role")
  node_iam_role_use_name_prefix = false
  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = merge(
    {
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    },
    var.services.karpenter.node_iam_role_additional_policies
  )

  node_iam_role_tags = merge(var.tags, var.services.karpenter.node_iam_role_additional_tags)

  service_account = var.services.karpenter.service_account_name

  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.iam_openid_provider.oidc_provider_arn
  irsa_namespace_service_accounts = ["${var.services.karpenter.namespace}:${var.services.karpenter.service_account_name}"]

  create_access_entry = var.services.karpenter.create_access_entry_for_node_iam_role

  tags = var.tags
}

################################################################################
# Deploy default nodeclass and nodepool
################################################################################

resource "kubectl_manifest" "karpenter_default_node_class" {

  count = var.services.karpenter.enabled && var.services.karpenter.deploy_default_nodeclass ? 1 : 0

  yaml_body = coalesce(var.services.karpenter.default_nodeclass_yaml, local.default_nodeclass_yaml)

  depends_on = [
    module.karpenter-helm
  ]
}

resource "kubectl_manifest" "karpenter_node_pools" {

  for_each = local.node_pools

  yaml_body = each.value

  depends_on = [
    kubectl_manifest.karpenter_default_node_class
  ]
}
