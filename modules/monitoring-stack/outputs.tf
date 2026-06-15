output "namespace" {
  description = "Namespace used by the monitoring stack."
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name for kube-prometheus-stack."
  value       = var.release_name
}

output "chart" {
  description = "Helm chart and version installed by Argo CD."
  value       = "kube-prometheus-stack@${var.chart_version}"
}

output "grafana_admin_secret_name" {
  description = "Secret used by Grafana for the local admin account."
  value       = kubernetes_secret_v1.grafana_admin.metadata[0].name
}

output "ingress_urls" {
  description = "Local URLs routed by ingress-nginx."
  value = {
    grafana      = "http://${var.grafana_ingress_host}"
    prometheus   = "http://${var.prometheus_ingress_host}"
    alertmanager = "http://${var.alertmanager_ingress_host}"
  }
}
