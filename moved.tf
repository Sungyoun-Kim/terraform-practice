moved {
  from = kubernetes_namespace_v1.ingress_nginx
  to   = module.ingress_nginx.kubernetes_namespace_v1.ingress_nginx
}

moved {
  from = helm_release.ingress_nginx
  to   = module.ingress_nginx.helm_release.ingress_nginx
}

moved {
  from = kubernetes_namespace_v1.monitoring
  to   = module.monitoring_stack.kubernetes_namespace_v1.monitoring
}

moved {
  from = helm_release.kube_prometheus_stack
  to   = module.monitoring_stack.helm_release.kube_prometheus_stack
}
