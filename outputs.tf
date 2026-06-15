output "namespace" {
  description = "Namespace used by the monitoring stack."
  value       = module.monitoring_stack.namespace
}

output "release_name" {
  description = "Helm release name for kube-prometheus-stack."
  value       = module.monitoring_stack.release_name
}

output "chart" {
  description = "Helm chart and version installed by Terraform."
  value       = module.monitoring_stack.chart
}

output "argocd_url" {
  description = "Local Argo CD URL routed by ingress-nginx."
  value       = module.argocd.url
}

output "argocd_initial_password_command" {
  description = "Command for reading the generated Argo CD admin password."
  value       = "kubectl --context ${var.kubernetes_context} -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
}

output "status_command" {
  description = "Check resources created by the Helm chart."
  value       = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} get pods,svc,pvc"
}

output "helm_status_command" {
  description = "Check Helm release status."
  value       = "helm status ${var.release_name} -n ${var.namespace}"
}

output "ingress_urls" {
  description = "Local URLs routed by ingress-nginx."
  value       = module.monitoring_stack.ingress_urls
}

output "ingress_status_command" {
  description = "Check ingress-nginx and monitoring Ingress resources."
  value       = "kubectl --context ${var.kubernetes_context} get ingressclass && kubectl --context ${var.kubernetes_context} -n ${var.namespace} get ingress"
}

output "port_forward_commands" {
  description = "Use these commands to open the Helm-installed UIs without LoadBalancer port conflicts."
  value = {
    grafana      = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/${var.release_name}-grafana 3001:3000"
    prometheus   = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/prometheus-operated 9091:9090"
    alertmanager = "kubectl --context ${var.kubernetes_context} -n ${var.namespace} port-forward svc/alertmanager-operated 9094:9093"
  }
}
