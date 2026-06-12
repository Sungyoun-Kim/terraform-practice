# Terraform Practice

Terraform을 로컬에서 손으로 익히기 위한 실습 repo입니다.

현재 구성은 하나의 Terraform 프로젝트로 Docker Desktop Kubernetes 클러스터에 Helm provider를 사용해서 `prometheus-community/kube-prometheus-stack` chart를 설치합니다.

## Current Project

- 대상 클러스터: Docker Desktop Kubernetes
- Terraform providers: `helm`, `kubernetes`
- Helm chart: `prometheus-community/kube-prometheus-stack` `86.2.2`
- Namespace: `monitoring-helm`
- Helm release: `prometheus-stack`

Terraform이 직접 관리하는 최상위 리소스는 Kubernetes namespace와 Helm release입니다. Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics, Prometheus Operator 같은 세부 Kubernetes 리소스는 Helm chart가 생성합니다.

## 사전 준비

필요한 것:

- Docker Desktop 실행 중
- Docker Desktop Kubernetes 활성화
- Terraform CLI 설치
- kubectl 설치
- Helm CLI 설치

Docker Desktop Kubernetes 확인:

```bash
kubectl config current-context
kubectl --context docker-desktop get nodes
```

이 repo는 실수로 다른 클러스터에 배포하지 않도록 기본 context를 `docker-desktop`으로 둡니다.

## 빠른 실행

```bash
terraform init
terraform plan
terraform apply
```

상태 확인:

```bash
kubectl --context docker-desktop -n monitoring-helm get pods,svc,pvc
helm status prometheus-stack -n monitoring-helm
```

정리:

```bash
terraform destroy
```

## UI 접속

이 프로젝트는 서비스를 `ClusterIP`로 둡니다. 로컬 브라우저에서 보려면 port-forward를 사용합니다.

Grafana:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/prometheus-stack-grafana 3001:3000
```

Prometheus:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/prometheus-operated 9091:9090
```

Alertmanager:

```bash
kubectl --context docker-desktop -n monitoring-helm port-forward svc/alertmanager-operated 9094:9093
```

접속 주소:

| 서비스 | 주소 |
| --- | --- |
| Grafana | <http://localhost:3001> |
| Prometheus | <http://localhost:9091> |
| Alertmanager | <http://localhost:9094> |

Grafana 기본 계정:

```text
admin / admin
```

## 추천 학습 순서

1. Provider 초기화 보기

   ```bash
   terraform init
   ```

   확인할 것:

   - `.terraform/`
   - `.terraform.lock.hcl`
   - `versions.tf`의 Helm/Kubernetes provider 선언

2. 실행 계획 읽기

   ```bash
   terraform plan
   ```

   확인할 리소스:

   - `kubernetes_namespace_v1.monitoring`
   - `helm_release.kube_prometheus_stack`

   직접 Kubernetes 리소스를 하나씩 선언할 때와 달리, Helm 방식은 Terraform state에 Helm release 단위로 잡힙니다.

3. 실제 리소스 생성

   ```bash
   terraform apply
   ```

   Kubernetes와 Helm 양쪽에서 확인합니다.

   ```bash
   kubectl --context docker-desktop -n monitoring-helm get all
   helm status prometheus-stack -n monitoring-helm
   ```

4. Terraform state 관찰

   ```bash
   terraform state list
   terraform state show helm_release.kube_prometheus_stack
   ```

   Terraform은 chart가 만든 모든 Pod/Service를 개별 resource로 들고 있지 않고, Helm release 하나를 추적합니다.

5. Helm values 변경해보기

   `values/kube-prometheus-stack.yaml`에서 Grafana, Prometheus, Alertmanager 설정을 바꾼 뒤 plan을 봅니다.

   ```bash
   terraform plan
   terraform apply
   ```

6. Chart 버전 변경해보기

   `variables.tf` 또는 `terraform.tfvars`의 `chart_version`을 바꾸면 Helm chart upgrade 흐름을 실습할 수 있습니다.

   ```bash
   terraform plan -var="chart_version=86.2.2"
   ```

7. Helm CLI로 내부 보기

   ```bash
   helm get values prometheus-stack -n monitoring-helm
   helm get manifest prometheus-stack -n monitoring-helm
   kubectl --context docker-desktop -n monitoring-helm get servicemonitor,podmonitor,prometheusrule
   ```

8. plan 결과 파일로 저장하기

   ```bash
   terraform plan -out=plan.tfplan
   terraform show -no-color plan.tfplan > plan.txt
   ```

9. 전체 삭제

   ```bash
   terraform destroy
   ```

   삭제 뒤 확인합니다.

   ```bash
   kubectl --context docker-desktop get namespace monitoring-helm
   ```

## 파일 구조

```text
.
├── main.tf
├── providers.tf
├── versions.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── values/
│   └── kube-prometheus-stack.yaml
├── Makefile
└── README.md
```

## Makefile

자주 쓰는 명령은 `make`로도 실행할 수 있습니다.

```bash
make init
make validate
make plan
make apply
make ps
make helm-status
make port-forward-grafana
```
