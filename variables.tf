variable "project_name" {
  description = "Prefix used for Docker container, network, and volume names."
  type        = string
  default     = "tf-prometheus-stack"
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

variable "cadvisor_version" {
  description = "cAdvisor Docker image tag. Used only when enable_cadvisor is true."
  type        = string
  default     = "v0.49.1"
}

variable "prometheus_port" {
  description = "Host port for Prometheus."
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Host port for Grafana."
  type        = number
  default     = 3000
}

variable "alertmanager_port" {
  description = "Host port for Alertmanager."
  type        = number
  default     = 9093
}

variable "node_exporter_port" {
  description = "Host port for node-exporter."
  type        = number
  default     = 9100
}

variable "cadvisor_port" {
  description = "Host port for cAdvisor. Used only when enable_cadvisor is true."
  type        = number
  default     = 8080
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

variable "enable_cadvisor" {
  description = "Enable the optional cAdvisor container and Prometheus scrape target."
  type        = bool
  default     = false
}
