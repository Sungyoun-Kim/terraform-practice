resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/lab"       = "helm-kube-prometheus-stack"
    }
  }
}
