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

variable "ingress_nginx_namespace" {
  description = "Kubernetes namespace where ingress-nginx is installed."
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_release_name" {
  description = "Helm release name for ingress-nginx."
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version."
  type        = string
  default     = "4.15.1"
}

variable "ingress_class_name" {
  description = "IngressClass name used by the local ingress controller."
  type        = string
  default     = "nginx"
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD is installed."
  type        = string
  default     = "argocd"
}

variable "argocd_release_name" {
  description = "Helm release name for Argo CD."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "argo/argo-cd Helm chart version."
  type        = string
  default     = "9.5.21"
}

variable "argocd_ingress_host" {
  description = "Hostname routed to the Argo CD server."
  type        = string
  default     = "argocd.localhost"
}

variable "gitops_repo_url" {
  description = "Git repository URL watched by the Argo CD root Application."
  type        = string
  default     = "https://github.com/Sungyoun-Kim/terraform-practice"
}

variable "gitops_target_revision" {
  description = "Git revision watched by the Argo CD root Application."
  type        = string
  default     = "main"
}
