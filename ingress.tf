resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = var.ingress_nginx_namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "ingress-nginx"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = var.ingress_nginx_release_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true

  values = [
    yamlencode({
      controller = {
        ingressClass = var.ingress_class_name

        ingressClassResource = {
          enabled = true
          name    = var.ingress_class_name
          default = false
        }

        admissionWebhooks = {
          enabled = false
        }

        service = {
          type = "LoadBalancer"
        }
      }
    }),
  ]
}

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

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.kube_prometheus_stack,
  ]
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

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.kube_prometheus_stack,
  ]
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

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.kube_prometheus_stack,
  ]
}
