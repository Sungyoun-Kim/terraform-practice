removed {
  from = module.monitoring_stack.helm_release.kube_prometheus_stack

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.monitoring_stack.kubernetes_secret_v1.grafana_admin

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_config_map_v1.import_lab

  lifecycle {
    destroy = false
  }
}
