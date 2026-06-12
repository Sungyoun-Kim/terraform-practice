locals {
  names = {
    prometheus                 = "prometheus"
    prometheus_config          = "prometheus-config"
    prometheus_data            = "prometheus-data"
    grafana                    = "grafana"
    grafana_admin              = "grafana-admin"
    grafana_data               = "grafana-data"
    grafana_datasource         = "grafana-datasource"
    grafana_dashboard_provider = "grafana-dashboard-provider"
    grafana_dashboard          = "grafana-dashboard"
    alertmanager               = "alertmanager"
    alertmanager_config        = "alertmanager-config"
    alertmanager_data          = "alertmanager-data"
    node_exporter              = "node-exporter"
  }

  common_labels = {
    "app.kubernetes.io/part-of"    = var.project_name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  selector_labels = {
    prometheus = {
      "app.kubernetes.io/name" = local.names.prometheus
    }

    grafana = {
      "app.kubernetes.io/name" = local.names.grafana
    }

    alertmanager = {
      "app.kubernetes.io/name" = local.names.alertmanager
    }

    node_exporter = {
      "app.kubernetes.io/name" = local.names.node_exporter
    }
  }
}
