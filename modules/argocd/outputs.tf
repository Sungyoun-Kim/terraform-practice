output "namespace" {
  description = "Namespace used by Argo CD."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "release_name" {
  description = "Helm release name for Argo CD."
  value       = helm_release.argocd.name
}

output "url" {
  description = "Local Argo CD URL routed by ingress-nginx."
  value       = "http://${var.ingress_host}"
}
