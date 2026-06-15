removed {
  from = module.monitoring_stack.helm_release.kube_prometheus_stack

  lifecycle {
    destroy = false
  }
}
