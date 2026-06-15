module "ingress_nginx" {
  source = "./modules/ingress-nginx"

  namespace          = var.ingress_nginx_namespace
  release_name       = var.ingress_nginx_release_name
  chart_version      = var.ingress_nginx_chart_version
  ingress_class_name = var.ingress_class_name
}

module "monitoring_stack" {
  source = "./modules/monitoring-stack"

  namespace              = var.namespace
  release_name           = var.release_name
  chart_version          = var.chart_version
  helm_values            = [file("${path.module}/values/kube-prometheus-stack.yaml")]
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password

  ingress_class_name        = var.ingress_class_name
  grafana_ingress_host      = var.grafana_ingress_host
  prometheus_ingress_host   = var.prometheus_ingress_host
  alertmanager_ingress_host = var.alertmanager_ingress_host

  depends_on = [
    module.ingress_nginx,
  ]
}
