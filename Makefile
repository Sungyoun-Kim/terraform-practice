CONTEXT ?= docker-desktop
NAMESPACE ?= monitoring-helm
RELEASE ?= prometheus-stack
BACKEND_CONFIG ?= backend/minio/backend.hcl
MINIO_ACCESS_KEY ?= minioadmin
MINIO_SECRET_KEY ?= minioadmin
MINIO_COMPOSE ?= docker compose -f backend/minio/compose.yaml
TF_BACKEND_ENV = AWS_ACCESS_KEY_ID=$(MINIO_ACCESS_KEY) AWS_SECRET_ACCESS_KEY=$(MINIO_SECRET_KEY)

.PHONY: backend-up backend-down backend-logs backend-objects backend-migrate init fmt validate plan plan-file apply destroy output state ps services pvc ingress ingress-controller helm-status helm-values helm-manifest port-forward-prometheus port-forward-grafana port-forward-alertmanager urls

backend-up:
	$(MINIO_COMPOSE) up -d

backend-down:
	$(MINIO_COMPOSE) down

backend-logs:
	$(MINIO_COMPOSE) logs -f minio

backend-objects:
	$(MINIO_COMPOSE) run --rm --entrypoint /bin/sh create-bucket -c 'mc alias set local http://minio:9000 "$${MINIO_ROOT_USER}" "$${MINIO_ROOT_PASSWORD}" && mc ls --recursive local/$${MINIO_BUCKET}'

backend-migrate:
	$(TF_BACKEND_ENV) terraform init -backend-config=$(BACKEND_CONFIG) -migrate-state -force-copy

init:
	$(TF_BACKEND_ENV) terraform init -backend-config=$(BACKEND_CONFIG)

fmt:
	terraform fmt -recursive

validate:
	terraform fmt -check -recursive
	terraform validate

plan:
	$(TF_BACKEND_ENV) terraform plan

plan-file:
	$(TF_BACKEND_ENV) terraform plan -out=plan.tfplan
	$(TF_BACKEND_ENV) terraform show -no-color plan.tfplan > plan.txt

apply:
	$(TF_BACKEND_ENV) terraform apply

destroy:
	$(TF_BACKEND_ENV) terraform destroy

output:
	$(TF_BACKEND_ENV) terraform output

state:
	$(TF_BACKEND_ENV) terraform state list

ps:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get pods

services:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get svc

pvc:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get pvc

ingress:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get ingress

ingress-controller:
	kubectl --context $(CONTEXT) -n ingress-nginx get pods,svc

helm-status:
	helm status $(RELEASE) -n $(NAMESPACE)

helm-values:
	helm get values $(RELEASE) -n $(NAMESPACE)

helm-manifest:
	helm get manifest $(RELEASE) -n $(NAMESPACE)

port-forward-prometheus:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/prometheus-operated 9091:9090

port-forward-grafana:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/$(RELEASE)-grafana 3001:3000

port-forward-alertmanager:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/alertmanager-operated 9094:9093

urls:
	@echo "Grafana:      http://grafana.localhost"
	@echo "Prometheus:   http://prometheus.localhost"
	@echo "Alertmanager: http://alertmanager.localhost"
