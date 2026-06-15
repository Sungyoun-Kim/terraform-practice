variable "namespace" {
  description = "Kubernetes namespace where Argo CD is installed."
  type        = string
}

variable "release_name" {
  description = "Helm release name for Argo CD."
  type        = string
}

variable "chart_version" {
  description = "argo/argo-cd Helm chart version."
  type        = string
}

variable "ingress_class_name" {
  description = "IngressClass name used by the Argo CD server Ingress."
  type        = string
}

variable "ingress_host" {
  description = "Hostname routed to the Argo CD server."
  type        = string
}
