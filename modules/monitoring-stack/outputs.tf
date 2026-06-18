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
