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

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password for local learning only."
  type        = string
  sensitive   = true
}

variable "ingress_class_name" {
  description = "IngressClass name used by monitoring Ingress resources."
  type        = string
}

variable "grafana_ingress_host" {
  description = "Hostname routed to Grafana through ingress-nginx."
  type        = string
}

variable "prometheus_ingress_host" {
  description = "Hostname routed to Prometheus through ingress-nginx."
  type        = string
}

variable "alertmanager_ingress_host" {
  description = "Hostname routed to Alertmanager through ingress-nginx."
  type        = string
}
