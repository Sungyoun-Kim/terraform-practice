output "namespace" {
  description = "Namespace used by the monitoring stack."
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name for kube-prometheus-stack."
  value       = helm_release.kube_prometheus_stack.name
}

output "chart" {
  description = "Helm chart and version installed by Terraform."
  value       = "${helm_release.kube_prometheus_stack.chart}@${helm_release.kube_prometheus_stack.version}"
}

output "ingress_urls" {
  description = "Local URLs routed by ingress-nginx."
  value = {
    grafana      = "http://${var.grafana_ingress_host}"
    prometheus   = "http://${var.prometheus_ingress_host}"
    alertmanager = "http://${var.alertmanager_ingress_host}"
  }
}
