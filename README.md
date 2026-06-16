# Terraform Practice

Terraform을 로컬에서 손으로 익히기 위한 실습 repo입니다.

현재 구성은 Docker Desktop Kubernetes 클러스터 위에 Terraform, Helm, Argo CD를 함께 사용하는 로컬 GitOps 실습 환경입니다.

## Current Project

- 대상 클러스터: Docker Desktop Kubernetes
- Terraform providers: `helm`, `kubernetes`
- Monitoring chart: `prometheus-community/kube-prometheus-stack` `86.2.2`
- Namespace: `monitoring-helm`
- Monitoring release name: `prometheus-stack`
- Ingress Controller: `ingress-nginx` `4.15.1`
- Argo CD: `argo/argo-cd` `9.5.21`
- Remote backend: local MinIO through Terraform S3 backend
- Local image registry: Docker Registry on `localhost:5001`
- GitOps demo app: `hello-app` served at <http://hello.localhost>

루트 프로젝트는 `modules/ingress-nginx`, `modules/argocd`, `modules/monitoring-stack`을 조립합니다. Terraform은 ingress-nginx, Argo CD, namespace, Ingress, bootstrap Application, Secret 같은 플랫폼 경계를 관리합니다. kube-prometheus-stack의 세부 Kubernetes 리소스는 Argo CD Application이 Helm chart를 렌더링해서 관리합니다.

샘플 `hello-app`은 Argo CD root Application이 이 repo의 `gitops/root` 경로를 바라보고, 그 안의 Application이 `charts/hello-app` Helm chart를 배포합니다. 이 흐름은 Terraform이 앱 Deployment를 직접 만들지 않고 Argo CD가 Git repo를 source of truth로 삼는 GitOps 연습용입니다.

## 사전 준비

필요한 것:

- Docker Desktop 실행 중
- Docker Desktop Kubernetes 활성화
- Terraform CLI 설치
- kubectl 설치
- Helm CLI 설치
- Docker Compose 설치

Docker Desktop Kubernetes 확인:

```bash
kubectl config current-context
kubectl --context docker-desktop get nodes
```

이 repo는 실수로 다른 클러스터에 배포하지 않도록 기본 context를 `docker-desktop`으로 둡니다.

## 빠른 실행

```bash
make backend-up
make registry-up
make demo-image
make init
make plan
make apply
```

Argo CD root Application은 GitHub 원격 repo를 읽습니다. `gitops/root`나 `charts/hello-app`을 새로 추가하거나 바꾼 뒤에는 변경사항을 push해야 Argo CD가 볼 수 있습니다.

상태 확인:

```bash
kubectl --context docker-desktop -n argocd get pods,svc,ingress
kubectl --context docker-desktop -n argocd get application kube-prometheus-stack
kubectl --context docker-desktop -n monitoring-helm get pods,svc,pvc
kubectl --context docker-desktop -n monitoring-helm get ingress
```

정리:

```bash
make destroy
```

## Remote Backend

이 repo는 로컬 MinIO를 Terraform S3 backend로 사용합니다.

| 역할 | 구성 |
| --- | --- |
| State 저장소 | MinIO bucket `terraform-state` |
| State key | `terraform-practice/prometheus-stack/terraform.tfstate` |
| Lock | S3 lockfile `terraform.tfstate.tflock` |
| MinIO API | <http://localhost:9000> |
| MinIO Console | <http://localhost:9001> |

MinIO 시작:

```bash
make backend-up
```

기존 local state를 MinIO로 이관:

```bash
make backend-migrate
```

State object 확인:

```bash
make backend-objects
```

기본 로컬 계정:

```text
minioadmin / minioadmin
```

credentials는 Terraform 코드에 넣지 않고 Makefile에서 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`로 주입합니다. 직접 Terraform 명령을 실행할 때는 아래처럼 환경변수를 함께 넘깁니다.

```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin terraform plan
```

Docker volume `minio_minio-data`를 삭제하면 이 로컬 remote state도 삭제됩니다.

## UI 접속

이 프로젝트는 `ingress-nginx`를 함께 설치해서 로컬 브라우저에서 Ingress hostname으로 접속합니다.

| 서비스 | Ingress 주소 |
| --- | --- |
| Argo CD | <http://argocd.localhost> |
| Hello App | <http://hello.localhost> |
| Grafana | <http://grafana.localhost> |
| Prometheus | <http://prometheus.localhost> |
| Alertmanager | <http://alertmanager.localhost> |

Argo CD 기본 계정은 `admin`입니다. 초기 비밀번호는 아래 명령으로 확인합니다.

```bash
make argocd-password
```

Grafana 기본 계정:

```text
admin / admin
```

Docker Desktop에서 `ingress-nginx-controller` 서비스는 `LoadBalancer` 타입으로 뜨며, 일반적으로 `localhost`의 80 포트로 연결됩니다.

```bash
kubectl --context docker-desktop -n ingress-nginx get svc
kubectl --context docker-desktop -n monitoring-helm get ingress
```

port-forward를 쓰고 싶을 때는 아래 명령을 별도로 실행합니다.

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

## 추천 학습 순서

1. Provider 초기화 보기

   ```bash
   make init
   ```

   확인할 것:

   - `.terraform/`
   - `.terraform.lock.hcl`
   - `backend.tf`
   - `backend/minio/backend.hcl`
   - `versions.tf`의 Helm/Kubernetes provider 선언

2. 실행 계획 읽기

   ```bash
   make plan
   ```

   확인할 리소스:

   - `module.monitoring_stack.kubernetes_namespace_v1.monitoring`
   - `module.monitoring_stack.kubernetes_secret_v1.grafana_admin`
   - `module.monitoring_stack.kubernetes_ingress_v1.*`
   - `module.ingress_nginx.kubernetes_namespace_v1.ingress_nginx`
   - `module.ingress_nginx.helm_release.ingress_nginx`
   - `module.argocd.kubernetes_namespace_v1.argocd`
   - `module.argocd.helm_release.argocd`
   - `kubernetes_manifest.kube_prometheus_stack_application`

   kube-prometheus-stack 자체는 Terraform `helm_release`가 아니라 Argo CD `Application`으로 잡힙니다.

3. 실제 리소스 생성

   ```bash
   make apply
   ```

   Kubernetes와 Helm 양쪽에서 확인합니다.

   ```bash
   kubectl --context docker-desktop -n monitoring-helm get all
   kubectl --context docker-desktop -n monitoring-helm get ingress
   kubectl --context docker-desktop -n ingress-nginx get pods,svc
   kubectl --context docker-desktop -n argocd get pods,svc,ingress
   kubectl --context docker-desktop -n argocd get application kube-prometheus-stack
   ```

4. Terraform state 관찰

   ```bash
   make state
   AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin terraform state show kubernetes_manifest.kube_prometheus_stack_application
   AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin terraform state show module.ingress_nginx.helm_release.ingress_nginx
   ```

   Terraform은 chart가 만든 모든 Pod/Service를 개별 resource로 들고 있지 않고, Argo CD Application을 bootstrap 리소스로 추적합니다. Ingress와 Grafana admin Secret은 Terraform 리소스로 직접 선언합니다.

5. Module 경계 보기

   루트 `main.tf`는 module 호출만 담당하고, 실제 리소스 선언은 module 내부에 있습니다.

   ```bash
   make state
   make plan
   ```

   `moved.tf`는 이전 루트 리소스 주소를 module 주소로 옮긴 기록입니다. 기존 리소스를 삭제/재생성하지 않고 코드 구조만 바꿀 때 사용합니다.

   `removed.tf`는 예전에 Terraform이 관리하던 `helm_release.kube_prometheus_stack`을 destroy 없이 state에서 제거한 이관 기록입니다. 지금 kube-prometheus-stack은 Argo CD가 관리합니다.

6. Helm values 변경해보기

   `values/kube-prometheus-stack.yaml`에서 Grafana, Prometheus, Alertmanager 설정을 바꾼 뒤 plan/apply를 실행합니다. Terraform은 Argo CD Application spec을 바꾸고, Argo CD가 클러스터 리소스를 sync합니다.

   ```bash
   make plan
   make apply
   ```

7. Chart 버전 변경해보기

   `variables.tf` 또는 `terraform.tfvars`의 `chart_version`을 바꾸면 Argo CD를 통한 Helm chart upgrade 흐름을 실습할 수 있습니다.

   ```bash
   AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin terraform plan -var="chart_version=86.2.2"
   ```

8. Argo CD로 내부 보기

   ```bash
   make argocd-app
   make argocd-app-values
   kubectl --context docker-desktop -n monitoring-helm get servicemonitor,podmonitor,prometheusrule
   ```

9. plan 결과 파일로 저장하기

   ```bash
   make plan-file
   ```

10. GitOps 이미지 업데이트 흐름 보기

   로컬 registry를 띄우고 샘플 이미지를 push합니다.

   ```bash
   make registry-up
   make demo-image
   make registry-tags
   ```

   샘플 앱은 `charts/hello-app/values-local.yaml`의 image 값을 사용합니다. `.github/workflows/update-hello-app-image.yaml` workflow는 이미지를 build/push하고 이 values 파일을 바꾸는 PR을 만들도록 작성되어 있습니다.

   GitHub-hosted runner의 `localhost`는 이 Mac이 아니라 GitHub runner 자신입니다. 그래서 `localhost:5001` registry는 GitHub-hosted Actions에서 접근할 수 없습니다. 로컬 registry로 실습하려면 이 Mac에 self-hosted runner를 붙이고 workflow dispatch 입력의 runner를 `self-hosted`로 둡니다. GitHub-hosted runner를 쓸 때는 GHCR/ECR 같은 외부 registry를 사용합니다.

   `act`로 GitHub Actions를 로컬 Docker에서 실행하면 이 Mac의 `localhost:5001` registry에 접근할 수 있습니다.

   ```bash
   brew install act

   TAG="act-$(date +%Y%m%d%H%M%S)"
   GITHUB_TOKEN="$(gh auth token)" act workflow_dispatch \
     -W .github/workflows/update-hello-app-image.yaml \
     -P ubuntu-latest=catthehacker/ubuntu:act-latest \
     --input phase=local \
     --input image_tag="${TAG}" \
     --input registry=localhost:5001 \
     --input image_repository=terraform-practice/hello-app \
     --input runner=ubuntu-latest \
     -s GITHUB_TOKEN
   ```

   이 workflow는 image가 이미 있으면 재사용하고, 없으면 build/push한 뒤 `charts/hello-app/values-local.yaml`의 tag를 바꾸는 PR을 만듭니다. PR을 merge하면 Argo CD가 Git 변경을 감지해서 `hello-app`을 새 이미지로 rollout합니다.

   ```bash
   kubectl --context docker-desktop -n argocd get application hello-app -o wide
   kubectl --context docker-desktop -n hello-app get deployment hello-app -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
   curl -I http://hello.localhost
   ```

   배포 흐름은 아래처럼 읽으면 됩니다.

   ```text
   app source change 또는 workflow_dispatch
   -> GitHub Actions 또는 act build
   -> local registry image push
   -> charts/hello-app/values-local.yaml 변경 PR
   -> PR merge
   -> Argo CD sync
   -> hello-app rollout
   ```

11. 전체 삭제

   ```bash
   make destroy
   ```

   삭제 뒤 확인합니다.

   ```bash
   kubectl --context docker-desktop get namespace monitoring-helm
   ```

## 파일 구조

```text
.
├── main.tf
├── backend.tf
├── argocd_applications.tf
├── moved.tf
├── removed.tf
├── providers.tf
├── versions.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── backend/
│   ├── minio/
│   │   ├── backend.hcl
│   │   ├── compose.yaml
│   │   └── README.md
│   └── registry/
│       ├── compose.yaml
│       └── README.md
├── apps/
│   └── hello-app/
│       ├── Dockerfile
│       └── index.html
├── charts/
│   └── hello-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-local.yaml
│       └── templates/
├── gitops/
│   └── root/
│       ├── hello-app.yaml
│       └── local-platform-project.yaml
├── .github/
│   └── workflows/
│       └── update-hello-app-image.yaml
├── modules/
│   ├── ingress-nginx/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── argocd/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring-stack/
│       ├── main.tf
│       ├── ingress.tf
│       ├── variables.tf
│       └── outputs.tf
├── values/
│   └── kube-prometheus-stack.yaml
├── Makefile
└── README.md
```

## Makefile

자주 쓰는 명령은 `make`로도 실행할 수 있습니다.

```bash
make init
make backend-up
make backend-migrate
make backend-objects
make registry-up
make demo-image
make registry-tags
make validate
make plan
make apply
make ps
make ingress
make ingress-controller
make argocd
make argocd-app
make argocd-root-app
make hello-app
make argocd-password
make helm-status
make urls
```
