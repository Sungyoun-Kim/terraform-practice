resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "grafana-ingress"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.grafana_ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${var.release_name}-grafana"

              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

}

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "prometheus-ingress"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.prometheus_ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${var.release_name}-kube-prom-prometheus"

              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

}

resource "kubernetes_ingress_v1" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "alertmanager-ingress"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.alertmanager_ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${var.release_name}-kube-prom-alertmanager"

              port {
                number = 9093
              }
            }
          }
        }
      }
    }
  }

}
