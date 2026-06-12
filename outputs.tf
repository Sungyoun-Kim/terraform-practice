output "prometheus_url" {
  description = "Prometheus web UI."
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "Grafana web UI."
  value       = "http://localhost:${var.grafana_port}"
}

output "alertmanager_url" {
  description = "Alertmanager web UI."
  value       = "http://localhost:${var.alertmanager_port}"
}

output "node_exporter_url" {
  description = "node-exporter metrics endpoint."
  value       = "http://localhost:${var.node_exporter_port}/metrics"
}

output "cadvisor_url" {
  description = "cAdvisor web UI. Null when enable_cadvisor is false."
  value       = var.enable_cadvisor ? "http://localhost:${var.cadvisor_port}" : null
}

output "grafana_admin_user" {
  description = "Grafana admin username."
  value       = var.grafana_admin_user
}

output "useful_prometheus_pages" {
  description = "Prometheus pages that are useful while learning."
  value = {
    targets = "http://localhost:${var.prometheus_port}/targets"
    alerts  = "http://localhost:${var.prometheus_port}/alerts"
    graph   = "http://localhost:${var.prometheus_port}/graph"
  }
}
