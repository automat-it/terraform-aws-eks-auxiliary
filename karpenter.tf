# Karpenter
locals {
  # Helm versions
  karpenter_helm_version = try(var.services["karpenter"]["helm_version"], "1.0.0")
  # External module version
  karpenter_external_module_version = try(var.services["karpenter"]["external_module_version"], "~> 20.0")
  # K8s namespace to deploy
  karpenter_namespace = try(var.services["karpenter"]["namespace"], kubernetes_namespace_v1.general.id)
  # K8S Service Account Name
  karpenter_service_account_name = try(var.services["karpenter"]["service_account_name"], "karpenter")
  # Karpenetr default NodeClass
  deploy_karpenetr_default_nodeclass = try(var.services["karpenter"]["deploy_karpenetr_default_nodeclass"], true)
  # Karpenetr default Nodepool
  deploy_karpenetr_default_nodepool = try(var.services["karpenter"]["deploy_karpenetr_default_nodepool"], true)
  # AWS IAM IRSA
  karpenter_irsa_iam_role_name = try(var.services["karpenter"]["irsa_iam_role_name"], "${var.cluster_name}-karpenter-iam-role")
  karpenter_node_iam_role_name = try(var.services["karpenter"]["node_iam_role_name"], "${var.cluster_name}-karpenter-worker-iam-role")
  # SG
  karpenter_node_security_group_id = try(var.services["karpenter"]["node_security_group_id"], "")
  # Helm ovveride values
  karpenter_helm_values = <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${data.aws_eks_cluster.this.endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    %{~if try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name) != ""~}
    nodeSelector:
      pool: ${try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name)}
    tolerations:
      - key: dedicated
        operator: Equal
        value: ${try(var.services["karpenter"]["nodepool"], var.cluster_nodepool_name)}
        effect: NoSchedule
    %{~endif~}
    EOT

  # Default karpenter nodeclass
  default_nodeclass_yaml = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        %{~if local.karpenter_node_security_group_id != ""~}
        - id: ${module.eks_dev.node_security_group_id}
        %{~endif~}
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
            kubernetes.io/cluster/${var.cluster_name}: owned
            "aws:eks:cluster-name": ${var.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: "20Gi"
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
        Name: "${var.cluster_name}-karpenetr-worker"
  YAML

  # Default karpenter nodepool
  default_nodepool_yaml = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t", "c", "m"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["2", "4"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
      limits:
        cpu: 100
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
  version = local.karpenter_external_module_version

  count = try(var.services["karpenter"]["enabled"], var.has_karpenter) ? 1 : 0

  cluster_name = module.eks_dev.cluster_name

  # IAM
  iam_role_name      = local.karpenter_irsa_iam_role_name
  node_iam_role_name = local.karpenter_node_iam_role_name

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

  count = var.services["karpenter"]["enabled"] && local.deploy_karpenetr_default_nodeclass ? 1 : 0

  yaml_body = try(var.services["karpenter"]["default_nodeclass_yaml"], local.default_nodeclass_yaml)

  depends_on = [
    module.karpenter-helm
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {

  count = var.services["karpenter"]["enabled"] && local.deploy_karpenetr_default_nodeclass ? 1 : 0

  yaml_body = try(var.services["karpenter"]["default_nodepool_yaml"], local.default_nodepool_yaml)

  depends_on = [
    kubectl_manifest.karpenter_default_node_class
  ]
}