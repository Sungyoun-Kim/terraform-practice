output "prometheus_url" {
  description = "Prometheus web UI. With Docker Desktop LoadBalancer services, this should be reachable on localhost."
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "Grafana web UI. With Docker Desktop LoadBalancer services, this should be reachable on localhost."
  value       = "http://localhost:${var.grafana_port}"
}

output "alertmanager_url" {
  description = "Alertmanager web UI. With Docker Desktop LoadBalancer services, this should be reachable on localhost."
  value       = "http://localhost:${var.alertmanager_port}"
}

output "grafana_admin_user" {
  description = "Grafana admin username."
  value       = var.grafana_admin_user
}

output "namespace" {
  description = "Kubernetes namespace used by this stack."
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "useful_prometheus_pages" {
  description = "Prometheus pages that are useful while learning."
  value = {
    targets = "http://localhost:${var.prometheus_port}/targets"
    alerts  = "http://localhost:${var.prometheus_port}/alerts"
    graph   = "http://localhost:${var.prometheus_port}/graph"
  }
}

output "kubectl_status_command" {
  description = "Command for checking Kubernetes resources created by Terraform."
  value       = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} get pods,svc,pvc"
}

output "port_forward_commands" {
  description = "Fallback commands if Docker Desktop LoadBalancer localhost routing is not available."
  value = {
    prometheus   = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/${local.names.prometheus} ${var.prometheus_port}:9090"
    grafana      = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/${local.names.grafana} ${var.grafana_port}:3000"
    alertmanager = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/${local.names.alertmanager} ${var.alertmanager_port}:9093"
  }
}
