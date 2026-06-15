resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "terraform-practice/component" = "argocd"
    }
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  atomic          = true
  cleanup_on_fail = true
  timeout         = 900
  wait            = true

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = "true"
        }
      }

      server = {
        ingress = {
          enabled          = true
          ingressClassName = var.ingress_class_name
          hostname         = var.ingress_host
          path             = "/"
          pathType         = "Prefix"
          tls              = false
        }
      }
    }),
  ]
}
