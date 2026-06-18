variable "namespace" {
  description = "Kubernetes namespace where the Helm chart is installed."
  type        = string
}

variable "release_name" {
  description = "Helm release name."
  type        = string
}

variable "chart_version" {
  description = "prometheus-community/kube-prometheus-stack chart version."
  type        = string
}
