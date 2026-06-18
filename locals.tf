locals {
  monitoring_values = yamldecode(file("${path.module}/values/kube-prometheus-stack.yaml"))

  monitoring_ingress_urls = {
    grafana      = "http://${local.monitoring_values.grafana.ingress.hosts[0]}"
    prometheus   = "http://${local.monitoring_values.prometheus.ingress.hosts[0]}"
    alertmanager = "http://${local.monitoring_values.alertmanager.ingress.hosts[0]}"
  }
}
