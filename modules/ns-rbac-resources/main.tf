# RBAC
locals {
  namespace                      = var.namespace
  group_name_rw                  = "namespace:${var.namespace}:rw"
  group_name_ro                  = "namespace:${var.namespace}:ro"
  namespace_rw_role_name         = "namespace-rw-access-role"
  namespace_ro_role_name         = "namespace-ro-access-role"
  namespace_rw_role_binding_name = "${var.namespace}-rw-role-binding"
  namespace_ro_role_binding_name = "${var.namespace}-ro-role-binding"
}

resource "kubernetes_role_v1" "rw" {
  metadata {
    name      = local.namespace_rw_role_name
    namespace = local.namespace
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}
resource "kubernetes_role_v1" "ro" {
  metadata {
    name      = local.namespace_ro_role_name
    namespace = local.namespace
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "rw" {
  metadata {
    name      = local.namespace_rw_role_binding_name
    namespace = local.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.namespace_rw_role_name
  }
  subject {
    kind      = "Group"
    name      = local.group_name_rw
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_binding_v1" "ro" {
  metadata {
    name      = local.namespace_ro_role_binding_name
    namespace = local.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.namespace_ro_role_name
  }
  subject {
    kind      = "Group"
    name      = local.group_name_ro
    api_group = "rbac.authorization.k8s.io"
  }
}