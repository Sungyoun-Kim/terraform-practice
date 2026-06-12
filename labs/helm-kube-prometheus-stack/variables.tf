variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by the Kubernetes and Helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubeconfig context to use. Docker Desktop normally creates a context named docker-desktop."
  type        = string
  default     = "docker-desktop"
}

variable "kubernetes_insecure_skip_tls_verify" {
  description = "Skip Kubernetes API TLS certificate verification. Keep false unless debugging a local kubeconfig issue."
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Kubernetes namespace where the Helm chart is installed."
  type        = string
  default     = "monitoring-helm"
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "prometheus-stack"
}

variable "chart_version" {
  description = "prometheus-community/kube-prometheus-stack chart version."
  type        = string
  default     = "86.2.2"
}

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password for local learning only."
  type        = string
  default     = "admin"
  sensitive   = true
}
