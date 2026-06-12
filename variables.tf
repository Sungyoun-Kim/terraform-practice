variable "project_name" {
  description = "Logical project label used across Kubernetes resources."
  type        = string
  default     = "tf-prometheus-stack"
}

variable "namespace" {
  description = "Kubernetes namespace where the monitoring stack is deployed."
  type        = string
  default     = "monitoring"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by the Kubernetes provider."
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubeconfig context to use. Docker Desktop normally creates a context named docker-desktop."
  type        = string
  default     = "docker-desktop"
}

variable "kubernetes_insecure_skip_tls_verify" {
  description = "Skip Kubernetes API TLS certificate verification. Use only for local broken Docker Desktop kubeconfig setups."
  type        = bool
  default     = false
}

variable "prometheus_version" {
  description = "Prometheus Docker image tag."
  type        = string
  default     = "v2.54.1"
}

variable "grafana_version" {
  description = "Grafana Docker image tag."
  type        = string
  default     = "11.2.0"
}

variable "alertmanager_version" {
  description = "Alertmanager Docker image tag."
  type        = string
  default     = "v0.27.0"
}

variable "node_exporter_version" {
  description = "Node exporter Docker image tag."
  type        = string
  default     = "v1.8.2"
}

variable "service_type" {
  description = "Kubernetes Service type for browser-facing services."
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "service_type must be one of ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "prometheus_port" {
  description = "Service port for Prometheus."
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Service port for Grafana."
  type        = number
  default     = 3000
}

variable "alertmanager_port" {
  description = "Service port for Alertmanager."
  type        = number
  default     = 9093
}

variable "node_exporter_port" {
  description = "Cluster-internal Service port for node-exporter."
  type        = number
  default     = 9100
}

variable "storage_class_name" {
  description = "StorageClass for PersistentVolumeClaims. Null uses the cluster default StorageClass."
  type        = string
  default     = null
}

variable "prometheus_storage_size" {
  description = "Persistent storage requested by Prometheus."
  type        = string
  default     = "2Gi"
}

variable "grafana_storage_size" {
  description = "Persistent storage requested by Grafana."
  type        = string
  default     = "1Gi"
}

variable "alertmanager_storage_size" {
  description = "Persistent storage requested by Alertmanager."
  type        = string
  default     = "512Mi"
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

variable "scrape_interval" {
  description = "Prometheus global scrape interval."
  type        = string
  default     = "15s"
}

variable "evaluation_interval" {
  description = "Prometheus rule evaluation interval."
  type        = string
  default     = "15s"
}
