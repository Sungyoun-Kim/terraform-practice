resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name   = var.namespace
    labels = local.common_labels
  }
}

resource "kubernetes_config_map_v1" "prometheus" {
  metadata {
    name      = local.names.prometheus_config
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.prometheus)
  }

  data = {
    "prometheus.yml" = templatefile("${path.module}/templates/prometheus.yml.tftpl", {
      scrape_interval      = var.scrape_interval
      evaluation_interval  = var.evaluation_interval
      prometheus_target    = "${local.names.prometheus}:9090"
      node_exporter_target = "${local.names.node_exporter}:${var.node_exporter_port}"
      alertmanager_target  = "${local.names.alertmanager}:9093"
    })

    "learning.rules.yml" = templatefile("${path.module}/templates/learning.rules.yml.tftpl", {})
  }
}

resource "kubernetes_config_map_v1" "alertmanager" {
  metadata {
    name      = local.names.alertmanager_config
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.alertmanager)
  }

  data = {
    "alertmanager.yml" = file("${path.module}/config/alertmanager/alertmanager.yml")
  }
}

resource "kubernetes_config_map_v1" "grafana_datasource" {
  metadata {
    name      = local.names.grafana_datasource
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  data = {
    "prometheus.yml" = file("${path.module}/config/grafana/provisioning/datasources/prometheus.yml")
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboard_provider" {
  metadata {
    name      = local.names.grafana_dashboard_provider
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  data = {
    "dashboards.yml" = file("${path.module}/config/grafana/provisioning/dashboards/dashboards.yml")
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboard" {
  metadata {
    name      = local.names.grafana_dashboard
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  data = {
    "terraform-learning-overview.json" = file("${path.module}/config/grafana/dashboards/terraform-learning-overview.json")
  }
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = local.names.grafana_admin
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  data = {
    "admin-user"     = var.grafana_admin_user
    "admin-password" = var.grafana_admin_password
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim_v1" "prometheus" {
  metadata {
    name      = local.names.prometheus_data
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.prometheus)
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name

    resources {
      requests = {
        storage = var.prometheus_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "grafana" {
  metadata {
    name      = local.names.grafana_data
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name

    resources {
      requests = {
        storage = var.grafana_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "alertmanager" {
  metadata {
    name      = local.names.alertmanager_data
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.alertmanager)
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name

    resources {
      requests = {
        storage = var.alertmanager_storage_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "prometheus" {
  metadata {
    name      = local.names.prometheus
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.prometheus)
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.selector_labels.prometheus
    }

    template {
      metadata {
        labels = merge(local.common_labels, local.selector_labels.prometheus)
      }

      spec {
        security_context {
          fs_group = 65534
        }

        container {
          name  = "prometheus"
          image = "prom/prometheus:${var.prometheus_version}"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus",
            "--web.console.libraries=/usr/share/prometheus/console_libraries",
            "--web.console.templates=/usr/share/prometheus/consoles",
            "--web.enable-lifecycle",
          ]

          port {
            name           = "http"
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus/prometheus.yml"
            sub_path   = "prometheus.yml"
            read_only  = true
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus/rules/learning.rules.yml"
            sub_path   = "learning.rules.yml"
            read_only  = true
          }

          volume_mount {
            name       = "prometheus-data"
            mount_path = "/prometheus"
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = 9090
            }

            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = 9090
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }

            limits = {
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "prometheus-config"

          config_map {
            name = kubernetes_config_map_v1.prometheus.metadata[0].name
          }
        }

        volume {
          name = "prometheus-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.prometheus.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "grafana" {
  metadata {
    name      = local.names.grafana
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.selector_labels.grafana
    }

    template {
      metadata {
        labels = merge(local.common_labels, local.selector_labels.grafana)
      }

      spec {
        security_context {
          fs_group = 472
        }

        container {
          name  = "grafana"
          image = "grafana/grafana:${var.grafana_version}"

          env {
            name = "GF_SECURITY_ADMIN_USER"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.grafana_admin.metadata[0].name
                key  = "admin-user"
              }
            }
          }

          env {
            name = "GF_SECURITY_ADMIN_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.grafana_admin.metadata[0].name
                key  = "admin-password"
              }
            }
          }

          env {
            name  = "GF_USERS_ALLOW_SIGN_UP"
            value = "false"
          }

          env {
            name  = "GF_ANALYTICS_REPORTING_ENABLED"
            value = "false"
          }

          env {
            name  = "GF_ANALYTICS_CHECK_FOR_UPDATES"
            value = "false"
          }

          port {
            name           = "http"
            container_port = 3000
          }

          volume_mount {
            name       = "grafana-data"
            mount_path = "/var/lib/grafana"
          }

          volume_mount {
            name       = "grafana-datasource"
            mount_path = "/etc/grafana/provisioning/datasources/prometheus.yml"
            sub_path   = "prometheus.yml"
            read_only  = true
          }

          volume_mount {
            name       = "grafana-dashboard-provider"
            mount_path = "/etc/grafana/provisioning/dashboards/dashboards.yml"
            sub_path   = "dashboards.yml"
            read_only  = true
          }

          volume_mount {
            name       = "grafana-dashboard"
            mount_path = "/etc/grafana/dashboards/terraform-learning-overview.json"
            sub_path   = "terraform-learning-overview.json"
            read_only  = true
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }

            initial_delay_seconds = 20
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }

            initial_delay_seconds = 60
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }

            limits = {
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "grafana-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.grafana.metadata[0].name
          }
        }

        volume {
          name = "grafana-datasource"

          config_map {
            name = kubernetes_config_map_v1.grafana_datasource.metadata[0].name
          }
        }

        volume {
          name = "grafana-dashboard-provider"

          config_map {
            name = kubernetes_config_map_v1.grafana_dashboard_provider.metadata[0].name
          }
        }

        volume {
          name = "grafana-dashboard"

          config_map {
            name = kubernetes_config_map_v1.grafana_dashboard.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "alertmanager" {
  metadata {
    name      = local.names.alertmanager
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.alertmanager)
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.selector_labels.alertmanager
    }

    template {
      metadata {
        labels = merge(local.common_labels, local.selector_labels.alertmanager)
      }

      spec {
        security_context {
          fs_group = 65534
        }

        container {
          name  = "alertmanager"
          image = "prom/alertmanager:${var.alertmanager_version}"

          args = [
            "--config.file=/etc/alertmanager/alertmanager.yml",
            "--storage.path=/alertmanager",
          ]

          port {
            name           = "http"
            container_port = 9093
          }

          volume_mount {
            name       = "alertmanager-config"
            mount_path = "/etc/alertmanager/alertmanager.yml"
            sub_path   = "alertmanager.yml"
            read_only  = true
          }

          volume_mount {
            name       = "alertmanager-data"
            mount_path = "/alertmanager"
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = 9093
            }

            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = 9093
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }

            limits = {
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "alertmanager-config"

          config_map {
            name = kubernetes_config_map_v1.alertmanager.metadata[0].name
          }
        }

        volume {
          name = "alertmanager-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.alertmanager.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_daemon_set_v1" "node_exporter" {
  metadata {
    name      = local.names.node_exporter
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.node_exporter)
  }

  spec {
    selector {
      match_labels = local.selector_labels.node_exporter
    }

    template {
      metadata {
        labels = merge(local.common_labels, local.selector_labels.node_exporter)
      }

      spec {
        host_network = true
        host_pid     = true

        toleration {
          operator = "Exists"
        }

        container {
          name  = "node-exporter"
          image = "prom/node-exporter:${var.node_exporter_version}"

          args = [
            "--path.procfs=/host/proc",
            "--path.sysfs=/host/sys",
            "--path.rootfs=/host/root",
            "--collector.filesystem.mount-points-exclude=^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)",
          ]

          port {
            name           = "metrics"
            container_port = 9100
          }

          volume_mount {
            name       = "proc"
            mount_path = "/host/proc"
            read_only  = true
          }

          volume_mount {
            name       = "sys"
            mount_path = "/host/sys"
            read_only  = true
          }

          volume_mount {
            name              = "root"
            mount_path        = "/host/root"
            read_only         = true
            mount_propagation = "HostToContainer"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }

            limits = {
              memory = "128Mi"
            }
          }
        }

        volume {
          name = "proc"

          host_path {
            path = "/proc"
          }
        }

        volume {
          name = "sys"

          host_path {
            path = "/sys"
          }
        }

        volume {
          name = "root"

          host_path {
            path = "/"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = local.names.prometheus
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.prometheus)
  }

  spec {
    type     = var.service_type
    selector = local.selector_labels.prometheus

    port {
      name        = "http"
      port        = var.prometheus_port
      target_port = 9090
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "grafana" {
  metadata {
    name      = local.names.grafana
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.grafana)
  }

  spec {
    type     = var.service_type
    selector = local.selector_labels.grafana

    port {
      name        = "http"
      port        = var.grafana_port
      target_port = 3000
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "alertmanager" {
  metadata {
    name      = local.names.alertmanager
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.alertmanager)
  }

  spec {
    type     = var.service_type
    selector = local.selector_labels.alertmanager

    port {
      name        = "http"
      port        = var.alertmanager_port
      target_port = 9093
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "node_exporter" {
  metadata {
    name      = local.names.node_exporter
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels    = merge(local.common_labels, local.selector_labels.node_exporter)
  }

  spec {
    type     = "ClusterIP"
    selector = local.selector_labels.node_exporter

    port {
      name        = "metrics"
      port        = var.node_exporter_port
      target_port = 9100
      protocol    = "TCP"
    }
  }
}
