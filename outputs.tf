output "alb_controller_irsa_role_name" {
  value = var.has_aws_lb_controller ? module.aws-load-balancer-controller[0].irsa_role_name : "Not Installed"
}
output "argocd_irsa_role_name" {
  value = var.has_argocd ? module.argocd[0].irsa_role_name : "Not Installed"
}