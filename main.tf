module "ingress_nginx" {
  source = "./modules/ingress-nginx"

  namespace          = var.ingress_nginx_namespace
  release_name       = var.ingress_nginx_release_name
  chart_version      = var.ingress_nginx_chart_version
  ingress_class_name = var.ingress_class_name
}

module "argocd" {
  source = "./modules/argocd"

  namespace          = var.argocd_namespace
  release_name       = var.argocd_release_name
  chart_version      = var.argocd_chart_version
  ingress_class_name = var.ingress_class_name
  ingress_host       = var.argocd_ingress_host

  depends_on = [
    module.ingress_nginx,
  ]
}

module "monitoring_stack" {
  source = "./modules/monitoring-stack"

  namespace     = var.namespace
  release_name  = var.release_name
  chart_version = var.chart_version

  depends_on = [
    module.ingress_nginx,
  ]
}
