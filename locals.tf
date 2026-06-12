locals {
  network_name = "${var.project_name}-network"

  container_names = {
    prometheus    = "${var.project_name}-prometheus"
    grafana       = "${var.project_name}-grafana"
    alertmanager  = "${var.project_name}-alertmanager"
    node_exporter = "${var.project_name}-node-exporter"
    cadvisor      = "${var.project_name}-cadvisor"
  }

  volume_names = {
    prometheus   = "${var.project_name}-prometheus-data"
    grafana      = "${var.project_name}-grafana-data"
    alertmanager = "${var.project_name}-alertmanager-data"
  }
}
