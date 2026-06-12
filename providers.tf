provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kubernetes_context
  insecure       = var.kubernetes_insecure_skip_tls_verify
}
