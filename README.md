# Terraform Prometheus Stack on Docker Desktop Kubernetes

로컬 Terraform 학습을 위해 Docker Desktop의 Kubernetes 클러스터 위에 Prometheus, Grafana, Alertmanager, node-exporter를 올리는 예제입니다.

이전 Docker provider 버전과 달리, 지금 구성은 Terraform이 Kubernetes 리소스를 직접 선언합니다.

Terraform으로 생성하는 리소스:

- Namespace
- ConfigMap
- Secret
- PersistentVolumeClaim
- Deployment
- DaemonSet
- Service

## 사전 준비

필요한 것:

- Docker Desktop 실행 중
- Docker Desktop Kubernetes 활성화
- Terraform CLI 설치
- kubectl 설치

Docker Desktop Kubernetes 확인:

```bash
kubectl config get-contexts
kubectl --context docker-desktop get nodes
```

이 repo는 실수로 다른 클러스터에 배포하지 않도록 Terraform provider가 기본적으로 `docker-desktop` context를 사용합니다.

## 빠른 실행

```bash
terraform init
terraform plan
terraform apply
```

상태 확인:

```bash
kubectl --context docker-desktop -n monitoring get pods,svc,pvc
```

접속 주소:

| 서비스 | 기본 주소 |
| --- | --- |
| Prometheus | <http://localhost:9090> |
| Grafana | <http://localhost:3000> |
| Alertmanager | <http://localhost:9093> |

Grafana 기본 계정:

- ID: `admin`
- PW: `admin`

Docker Desktop의 `LoadBalancer` 서비스가 localhost로 바로 붙지 않으면 port-forward를 사용합니다.

```bash
kubectl --context docker-desktop -n monitoring port-forward svc/prometheus 9090:9090
kubectl --context docker-desktop -n monitoring port-forward svc/grafana 3000:3000
kubectl --context docker-desktop -n monitoring port-forward svc/alertmanager 9093:9093
```

정리:

```bash
terraform destroy
```

## 추천 학습 순서

1. Provider 초기화 보기

   ```bash
   terraform init
   ```

   확인할 것:

   - `.terraform/`
   - `.terraform.lock.hcl`
   - `versions.tf`의 Kubernetes provider 선언

2. 실행 계획 읽기

   ```bash
   terraform plan
   ```

   확인할 리소스:

   - `kubernetes_namespace_v1.monitoring`
   - `kubernetes_config_map_v1.*`
   - `kubernetes_secret_v1.grafana_admin`
   - `kubernetes_persistent_volume_claim_v1.*`
   - `kubernetes_deployment_v1.*`
   - `kubernetes_daemon_set_v1.node_exporter`
   - `kubernetes_service_v1.*`

3. 실제 리소스 생성

   ```bash
   terraform apply
   ```

   Kubernetes 쪽에서도 확인합니다.

   ```bash
   kubectl --context docker-desktop -n monitoring get all
   kubectl --context docker-desktop -n monitoring get configmap,secret,pvc
   ```

4. Prometheus target 확인

   브라우저에서 엽니다.

   - <http://localhost:9090/targets>
   - <http://localhost:9090/alerts>
   - <http://localhost:9090/graph>

   PromQL 예시:

   ```promql
   up
   scrape_duration_seconds
   sum(up)
   ```

5. Grafana provisioning 확인

   <http://localhost:3000> 접속 후 `admin` / `admin`으로 로그인합니다.

   확인할 것:

   - Prometheus datasource가 자동 생성되었는지
   - `Terraform Learning Overview` dashboard가 자동 생성되었는지

6. 일부러 alert 발생시키기

   node-exporter DaemonSet을 잠시 0개로 줄입니다.

   ```bash
   kubectl --context docker-desktop -n monitoring patch daemonset node-exporter \
     --type='json' \
     -p='[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"learning":"break"}}]'
   ```

   1분 정도 기다린 뒤 확인합니다.

   - <http://localhost:9090/alerts>
   - <http://localhost:9093>

   Terraform 코드 기준으로 다시 복구합니다.

   ```bash
   terraform apply
   ```

7. 변수를 바꿔서 plan 차이 보기

   예를 들어 scrape interval을 바꿔봅니다.

   ```bash
   terraform plan -var="scrape_interval=5s"
   terraform apply -var="scrape_interval=5s"
   ```

   Prometheus ConfigMap과 Deployment rollout이 어떻게 바뀌는지 확인합니다.

8. 상태 파일 관찰

   ```bash
   terraform state list
   terraform state show kubernetes_deployment_v1.prometheus
   ```

   확인할 것:

   - Terraform state가 Kubernetes 리소스와 어떻게 연결되는지
   - kubectl로 수동 변경한 drift가 plan에 어떻게 잡히는지

9. 전체 삭제

   ```bash
   terraform destroy
   ```

   삭제 뒤 확인합니다.

   ```bash
   kubectl --context docker-desktop get namespace monitoring
   ```

## 파일 구조

```text
.
├── main.tf
├── providers.tf
├── versions.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── terraform.tfvars.example
├── templates/
│   ├── prometheus.yml.tftpl
│   └── learning.rules.yml.tftpl
├── config/
│   ├── alertmanager/
│   │   └── alertmanager.yml
│   └── grafana/
│       ├── dashboards/
│       │   └── terraform-learning-overview.json
│       └── provisioning/
│           ├── dashboards/
│           │   └── dashboards.yml
│           └── datasources/
│               └── prometheus.yml
└── README.md
```

## 주요 파일 읽는 순서

1. `versions.tf`: Terraform/provider 버전
2. `providers.tf`: Kubernetes provider와 kubeconfig context
3. `variables.tf`: 조절 가능한 입력값
4. `locals.tf`: Kubernetes 리소스 이름과 label 규칙
5. `main.tf`: Kubernetes 리소스 본문
6. `templates/prometheus.yml.tftpl`: Prometheus scrape 설정
7. `templates/learning.rules.yml.tftpl`: alert rule
8. `config/grafana/provisioning/datasources/prometheus.yml`: Grafana datasource 자동 등록
9. `config/grafana/provisioning/dashboards/dashboards.yml`: Grafana dashboard 자동 등록

## 자주 부딪히는 문제

Docker Desktop Kubernetes가 꺼져 있음:

```text
The connection to the server localhost:6443 was refused
```

해결:

- Docker Desktop 설정에서 Kubernetes를 활성화
- Docker Desktop 재시작

다른 Kubernetes context에 배포될까 걱정될 때:

```bash
terraform plan -var="kubernetes_context=docker-desktop"
```

TLS 인증서 문제가 날 때:

```text
x509: certificate signed by unknown authority
```

우선 Docker Desktop Kubernetes를 재시작하거나 reset하는 편이 좋습니다. 로컬 학습용 임시 우회가 필요하면:

```bash
terraform plan -var="kubernetes_insecure_skip_tls_verify=true"
```

Grafana 로그 확인:

```bash
kubectl --context docker-desktop -n monitoring logs deploy/grafana
```

Prometheus 로그 확인:

```bash
kubectl --context docker-desktop -n monitoring logs deploy/prometheus
```

## 편의 명령

`make`가 있으면 다음 명령을 사용할 수 있습니다.

```bash
make init
make plan
make apply
make validate
make ps
make services
make pvc
make port-forward-grafana
make destroy
```
