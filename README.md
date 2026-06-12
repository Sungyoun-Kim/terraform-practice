# Terraform Prometheus Stack on Docker Desktop

로컬 Terraform 학습을 위해 Docker Desktop 위에 Prometheus, Grafana, Alertmanager, node-exporter를 올리는 예제입니다.

기본 목표는 운영용 완성본이 아니라, Terraform이 Docker 리소스를 어떻게 선언하고 변경하고 삭제하는지 손으로 확인하는 것입니다.

## 구성

Terraform으로 생성하는 리소스:

- Docker network 1개
- Docker volume 3개
- Prometheus 컨테이너
- Grafana 컨테이너
- Alertmanager 컨테이너
- node-exporter 컨테이너
- 선택 사항: cAdvisor 컨테이너
- Prometheus 설정 파일과 alert rule 생성

접속 주소:

| 서비스 | 주소 | 용도 |
| --- | --- | --- |
| Prometheus | <http://localhost:9090> | metric query, target 상태, alert 확인 |
| Grafana | <http://localhost:3000> | dashboard 확인 |
| Alertmanager | <http://localhost:9093> | firing alert 라우팅 확인 |
| node-exporter | <http://localhost:9100/metrics> | node metric 원문 확인 |
| cAdvisor | <http://localhost:8080> | 선택 사항, 컨테이너 metric 확인 |

Grafana 기본 계정:

- ID: `admin`
- PW: `admin`

## 사전 준비

필요한 것:

- Docker Desktop 실행 중
- Terraform CLI 설치

확인:

```bash
docker version
terraform version
```

## 빠른 실행

```bash
terraform init
terraform plan
terraform apply
```

`terraform apply`가 끝나면 output에 Prometheus, Grafana, Alertmanager URL이 출력됩니다.

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

   - `.terraform/` 디렉토리
   - `.terraform.lock.hcl`
   - `versions.tf`의 provider 선언

2. 실행 계획 읽기

   ```bash
   terraform plan
   ```

   확인할 것:

   - `docker_network.monitoring`
   - `docker_volume.*`
   - `docker_image.*`
   - `docker_container.*`
   - `local_file.prometheus_config`

3. 실제 리소스 생성

   ```bash
   terraform apply
   ```

   Docker 쪽에서도 확인합니다.

   ```bash
   docker ps
   docker network ls
   docker volume ls
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

   node-exporter를 잠시 멈춥니다.

   ```bash
   docker stop tf-prometheus-stack-node-exporter
   ```

   1분 정도 기다린 뒤 확인합니다.

   - <http://localhost:9090/alerts>
   - <http://localhost:9093>

   다시 복구합니다.

   ```bash
   docker start tf-prometheus-stack-node-exporter
   ```

7. 변수를 바꿔서 plan 차이 보기

   예를 들어 scrape interval을 바꿔봅니다.

   ```bash
   terraform plan -var="scrape_interval=5s"
   terraform apply -var="scrape_interval=5s"
   ```

   Prometheus 설정 파일이 다시 생성되고, Prometheus 컨테이너가 교체되는지 확인합니다.

8. cAdvisor 옵션 켜보기

   cAdvisor는 컨테이너 metric을 보기 좋지만, Docker Desktop의 파일 공유/마운트 정책에 따라 환경별 차이가 있습니다.

   ```bash
   terraform plan -var="enable_cadvisor=true"
   terraform apply -var="enable_cadvisor=true"
   ```

   문제가 생기면 기본값인 `false`로 두고 학습을 이어가면 됩니다.

9. 상태 파일 관찰

   ```bash
   terraform state list
   terraform state show docker_container.prometheus
   ```

   확인할 것:

   - Terraform state가 실제 Docker 리소스와 어떻게 연결되는지
   - 변수 변경이 state와 plan에 어떻게 반영되는지

10. 전체 삭제

    ```bash
    terraform destroy
    ```

    삭제 뒤 확인합니다.

    ```bash
    docker ps -a
    docker volume ls
    docker network ls
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
├── generated/
│   └── prometheus/
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

처음 볼 때는 이 순서가 편합니다.

1. `versions.tf`: Terraform/provider 버전
2. `providers.tf`: Docker provider 설정
3. `variables.tf`: 조절 가능한 입력값
4. `locals.tf`: 이름 규칙
5. `main.tf`: Docker 리소스 본문
6. `templates/prometheus.yml.tftpl`: Prometheus scrape 설정
7. `templates/learning.rules.yml.tftpl`: alert rule
8. `config/grafana/provisioning/datasources/prometheus.yml`: Grafana datasource 자동 등록
9. `config/grafana/provisioning/dashboards/dashboards.yml`: Grafana dashboard 자동 등록

## 자주 부딪히는 문제

포트 충돌:

```text
Error starting userland proxy: listen tcp 0.0.0.0:3000: bind: address already in use
```

해결:

```bash
terraform apply -var="grafana_port=3001"
```

Docker Desktop이 꺼져 있음:

```text
Cannot connect to the Docker daemon
```

해결:

- Docker Desktop을 실행한 뒤 다시 `terraform plan` 또는 `terraform apply`

Grafana 로그 확인:

```bash
docker logs tf-prometheus-stack-grafana
```

Prometheus 로그 확인:

```bash
docker logs tf-prometheus-stack-prometheus
```

## 편의 명령

`make`가 있으면 다음 명령을 사용할 수 있습니다.

```bash
make init
make plan
make apply
make validate
make ps
make output
make destroy
```
