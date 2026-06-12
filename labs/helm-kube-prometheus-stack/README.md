# Helm Provider Lab: kube-prometheus-stack

이 lab은 Terraform Helm provider로 `prometheus-community/kube-prometheus-stack` chart를 설치합니다.

Root lab이 Kubernetes 리소스를 직접 선언하는 방식이라면, 이 lab은 Helm chart를 Terraform에서 관리하는 방식입니다.

## What This Installs

- Prometheus Operator
- Prometheus
- Grafana
- Alertmanager
- node-exporter
- kube-state-metrics
- ServiceMonitor/PodMonitor/PrometheusRule CRDs

Chart:

```text
prometheus-community/kube-prometheus-stack 86.2.2
```

## Run

```bash
cd labs/helm-kube-prometheus-stack
terraform init
terraform plan
terraform apply
```

Status:

```bash
kubectl --context docker-desktop -n monitoring-helm get pods,svc,pvc
```

Helm release:

```bash
helm status prometheus-stack -n monitoring-helm
```

`helm` CLI is useful for inspection, but Terraform does not require the CLI to install the chart.

## Open UIs

This lab uses `ClusterIP` services to avoid colliding with the root lab's localhost ports.

Grafana:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/prometheus-stack-grafana 3001:3000
```

Open:

```text
http://localhost:3001
```

Default login:

```text
admin / admin
```

Prometheus:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/prometheus-operated 9091:9090
```

Open:

```text
http://localhost:9091
```

Alertmanager:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/alertmanager-operated 9094:9093
```

Open:

```text
http://localhost:9094
```

## Learning Points

Compare this lab with the root Terraform project:

| Topic | Direct Kubernetes lab | Helm provider lab |
| --- | --- | --- |
| Resource granularity | Terraform manages each K8s object | Terraform manages one Helm release |
| Diff readability | Very explicit | Values-driven, chart internals hidden |
| Upgrade workflow | Change Terraform resources | Change chart version and values |
| Reuse | Manual | Uses community-maintained chart |
| Debugging | `kubectl describe` each resource | `terraform`, `helm`, and `kubectl` together |

Useful commands:

```bash
terraform state list
terraform state show helm_release.kube_prometheus_stack
helm get values prometheus-stack -n monitoring-helm
helm get manifest prometheus-stack -n monitoring-helm
kubectl --context docker-desktop -n monitoring-helm get servicemonitor,podmonitor,prometheusrule
```

## Destroy

```bash
terraform destroy
```

Helm does not always remove CRDs installed by charts. If you want to inspect leftover CRDs after destroy:

```bash
kubectl get crd | grep monitoring.coreos.com
```
