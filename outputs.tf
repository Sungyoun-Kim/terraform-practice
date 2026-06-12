output "namespace" {
  description = "Namespace used by this Helm lab."
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.kube_prometheus_stack.name
}

output "chart" {
  description = "Helm chart and version installed by Terraform."
  value       = "${helm_release.kube_prometheus_stack.chart}@${helm_release.kube_prometheus_stack.version}"
}

output "status_command" {
  description = "Check resources created by the Helm chart."
  value       = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} get pods,svc,pvc"
}

output "helm_status_command" {
  description = "Check Helm release status."
  value       = "helm status ${var.release_name} -n ${var.namespace}"
}

output "port_forward_commands" {
  description = "Use these commands to open the Helm-installed UIs without LoadBalancer port conflicts."
  value = {
    grafana      = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/${var.release_name}-grafana 3001:3000"
    prometheus   = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/prometheus-operated 9091:9090"
    alertmanager = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/alertmanager-operated 9094:9093"
  }
}
