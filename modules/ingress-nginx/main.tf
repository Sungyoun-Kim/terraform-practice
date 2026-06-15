resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "ingress-nginx"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = var.release_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version
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
