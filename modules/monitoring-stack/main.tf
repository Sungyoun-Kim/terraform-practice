resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/lab"       = "helm-kube-prometheus-stack"
    }
  }
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "${var.release_name}-grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "grafana-admin"
    }
  }

  data = {
    admin-user     = var.grafana_admin_user
    admin-password = var.grafana_admin_password
  }

  type = "Opaque"
}
