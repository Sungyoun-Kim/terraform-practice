output "namespace" {
  description = "Namespace used by ingress-nginx."
  value       = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
}

output "release_name" {
  description = "Helm release name for ingress-nginx."
  value       = helm_release.ingress_nginx.name
}

output "ingress_class_name" {
  description = "IngressClass name created by ingress-nginx."
  value       = var.ingress_class_name
}
