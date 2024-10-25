# Karpenter
locals {
  # Helm versions. Please change the public submodule version in the apropriet line 'module "karpenter" {'
  karpenter_helm_version = try(var.services["karpenter"]["helm_version"], "1.0.0")
  # K8s namespace to deploy
  karpenter_namespace = try(var.services["karpenter"]["namespace"], kubernetes_namespace_v1.general.id)
  # K8S Service Account Name
  karpenter_service_account_name = try(var.services["karpenter"]["service_account_name"], "karpenter")
  # Karpenter default NodeClass
  deploy_karpenter_default_nodeclass            = try(var.services["karpenter"]["deploy_karpenter_default_nodeclass"], true)
  karpenter_default_nodeclass_ami_family        = try(var.services["karpenter"]["karpenter_default_nodeclass_ami_family"], "AL2023")
  karpenter_default_nodeclass_ami_alias         = try(var.services["karpenter"]["karpenter_default_nodeclass_ami_alias"], "al2023@latest")
  karpenter_default_nodeclass_name              = try(var.services["karpenter"]["karpenter_default_nodeclass_name"], "default")
  karpenter_default_nodeclass_volume_size       = try(var.services["karpenter"]["karpenter_default_nodeclass_volume_size"], "20Gi")
  karpenter_default_nodeclass_instance_category = try(var.services["karpenter"]["karpenter_default_nodeclass_instance_category"], ["t", "c", "m"])
  karpenter_default_nodeclass_instance_cpu      = try(var.services["karpenter"]["karpenter_default_nodeclass_instance_cpu"], ["2", "4"])
  # Karpenter default Nodepool
  deploy_karpenter_default_nodepool        = try(var.services["karpenter"]["deploy_karpenter_default_nodepool"], true)
  karpenter_default_nodepool_cpu_limit     = try(var.services["karpenter"]["karpenter_default_nodepool_cpu_limit"], "100")
  karpenter_default_nodepool_capacity_type = try(var.services["karpenter"]["karpenter_default_nodepool_capacity_type"], ["on-demand"])
  # AWS IAM IRSA
  karpenter_irsa_iam_role_name          = try(var.services["karpenter"]["irsa_iam_role_name"], "")
  karpenter_irsa_iam_role_name_prefix   = try(var.services["karpenter"]["irsa_iam_role_name_prefix"], "KarpenterController")
  karpenter_irsa_iam_policy_name        = try(var.services["karpenter"]["irsa_iam_policy_name"], "")
  karpenter_irsa_iam_policy_name_prefix = try(var.services["karpenter"]["irsa_iam_policy_name_prefix"], "KarpenterController")
  karpenter_node_iam_role_name          = try(var.services["karpenter"]["node_iam_role_name"], "")
  karpenter_node_iam_role_name_prefix   = try(var.services["karpenter"]["node_iam_role_name"], null)
  # SG
  karpenter_node_security_group_id = try(var.services["karpenter"]["node_security_group_id"], "")
  # Helm ovveride values
  karpenter_helm_values = <<-EOT
    serviceAccount:
      %{~if try(module.karpenter[0].service_account, "") != ""~}
      name: ${module.karpenter[0].service_account}
      %{~endif~}
      %{~if try(module.karpenter[0].iam_role_arn, "") != ""~}
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter[0].iam_role_arn}
      %{~endif~}
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${data.aws_eks_cluster.this.endpoint}
      %{~if try(module.karpenter[0].queue_name, "") != ""~}
      interruptionQueue: ${module.karpenter[0].queue_name}
      %{~endif~}
    %{~if try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name) != ""~}
    nodeSelector:
      pool: ${try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name)}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: dedicated
        operator: Equal
        value: ${try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name)}
        effect: NoSchedule
    %{~endif~}
    EOT

  # Default karpenter nodeclass
  default_nodeclass_yaml = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: ${local.karpenter_default_nodeclass_name}
    spec:
    %{~if local.karpenter_default_nodeclass_ami_family != ""~}
      amiFamily: ${local.karpenter_default_nodeclass_ami_family}
    %{~endif~}
      amiSelectorTerms:
        - alias: ${local.karpenter_default_nodeclass_ami_alias}
      %{~if try(module.karpenter[0].node_iam_role_name, "") != ""~}
      role: ${module.karpenter[0].node_iam_role_name}
      %{~endif~}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        %{~if local.karpenter_node_security_group_id != ""~}
        - id: ${local.karpenter_node_security_group_id}
        %{~endif~}
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
            kubernetes.io/cluster/${var.cluster_name}: owned
            "aws:eks:cluster-name": ${var.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: ${local.karpenter_default_nodeclass_volume_size}
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
        Name: "${var.cluster_name}-Karpenter-worker"
  YAML

  # Default karpenter nodepool
  default_nodepool_yaml = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
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
              values: ${jsonencode(local.karpenter_default_nodeclass_instance_category)}
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ${jsonencode(local.karpenter_default_nodeclass_instance_cpu)}
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values:  ${jsonencode(local.karpenter_default_nodepool_capacity_type)}
      limits:
        cpu: ${local.karpenter_default_nodepool_cpu_limit}
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML
}

################################################################################
# Karpenter helm
################################################################################

module "karpenter-helm" {
  source       = "./modules/helm-chart"
  count        = try(var.services["karpenter"]["enabled"], var.has_karpenter) ? 1 : 0
  name         = "karpenter"
  repository   = "oci://public.ecr.aws/karpenter"
  chart        = "karpenter"
  namespace    = local.karpenter_namespace
  helm_version = local.karpenter_helm_version

  values = [
    local.karpenter_helm_values,
    try(var.services["karpenter"]["additional_helm_values"], "")
  ]

  depends_on = [kubernetes_namespace_v1.general]
}

################################################################################
# Karpenter external module
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  count = try(var.services["karpenter"]["enabled"], var.has_karpenter) ? 1 : 0

  cluster_name = var.cluster_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  # IAM
  iam_role_name                 = length(local.karpenter_irsa_iam_role_name) > 0 ? local.karpenter_irsa_iam_role_name : local.karpenter_irsa_iam_role_name_prefix
  iam_role_use_name_prefix      = length(local.karpenter_irsa_iam_role_name) > 0 == false
  iam_policy_name               = length(local.karpenter_irsa_iam_policy_name) > 0 ? local.karpenter_irsa_iam_policy_name : local.karpenter_irsa_iam_policy_name_prefix
  iam_policy_use_name_prefix    = length(local.karpenter_irsa_iam_policy_name) > 0 == false
  node_iam_role_name            = length(local.karpenter_irsa_iam_role_name) > 0 ? local.karpenter_node_iam_role_name : local.karpenter_node_iam_role_name_prefix
  node_iam_role_use_name_prefix = length(local.karpenter_node_iam_role_name) > 0 == false

  # EKS Fargate currently does not support Pod Identity
  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.iam_openid_provider.oidc_provider_arn
  irsa_namespace_service_accounts = ["${local.karpenter_namespace}:${local.karpenter_service_account_name}"]

  create_access_entry = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}

################################################################################
# Deploy default nodeclass and nodepool
################################################################################

resource "kubectl_manifest" "karpenter_default_node_class" {

  count = var.services["karpenter"]["enabled"] && local.deploy_karpenter_default_nodeclass ? 1 : 0

  yaml_body = try(var.services["karpenter"]["default_nodeclass_yaml"], local.default_nodeclass_yaml)

  depends_on = [
    module.karpenter-helm
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {

  count = var.services["karpenter"]["enabled"] && local.deploy_karpenter_default_nodepool ? 1 : 0

  yaml_body = try(var.services["karpenter"]["default_nodepool_yaml"], local.default_nodepool_yaml)

  depends_on = [
    kubectl_manifest.karpenter_default_node_class
  ]
}
