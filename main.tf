resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/lab"       = "helm-kube-prometheus-stack"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  atomic          = true
  cleanup_on_fail = true
  timeout         = 900
  wait            = true

  values = [
    file("${path.module}/values/kube-prometheus-stack.yaml"),
  ]

  set {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
}
