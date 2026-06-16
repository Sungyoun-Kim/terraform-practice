resource "kubernetes_manifest" "kube_prometheus_stack_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kube-prometheus-stack"
      namespace = module.argocd.namespace

      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "terraform-practice/component" = "monitoring-application"
      }
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://prometheus-community.github.io/helm-charts"
        chart          = "kube-prometheus-stack"
        targetRevision = var.chart_version

        helm = {
          releaseName = var.release_name
          values      = file("${path.module}/values/kube-prometheus-stack.yaml")
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = module.monitoring_stack.namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=false",
          "ServerSideApply=true",
        ]
      }
    }
  }

  depends_on = [
    module.argocd,
    module.monitoring_stack,
  ]
}

resource "kubernetes_manifest" "gitops_root_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "terraform-practice-root"
      namespace = module.argocd.namespace

      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "terraform-practice/component" = "gitops-root"
      }
    }

    spec = {
      project = "default"

      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = "gitops/root"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = module.argocd.namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=false",
          "ServerSideApply=true",
        ]
      }
    }
  }

  depends_on = [
    module.argocd,
  ]
}
