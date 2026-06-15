variable "namespace" {
  description = "Kubernetes namespace where ingress-nginx is installed."
  type        = string
}

variable "release_name" {
  description = "Helm release name for ingress-nginx."
  type        = string
}

variable "chart_version" {
  description = "ingress-nginx Helm chart version."
  type        = string
}

variable "ingress_class_name" {
  description = "IngressClass name created by the ingress-nginx controller."
  type        = string
}
