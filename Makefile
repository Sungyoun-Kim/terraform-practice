CONTEXT ?= docker-desktop
NAMESPACE ?= monitoring-helm
RELEASE ?= prometheus-stack
ARGOCD_NAMESPACE ?= argocd
ARGOCD_APP ?= kube-prometheus-stack
ARGOCD_ROOT_APP ?= terraform-practice-root
HELLO_APP_NAMESPACE ?= hello-app
BACKEND_CONFIG ?= backend/minio/backend.hcl
MINIO_ACCESS_KEY ?= minioadmin
MINIO_SECRET_KEY ?= minioadmin
MINIO_COMPOSE ?= docker compose -f backend/minio/compose.yaml
TF_BACKEND_ENV = AWS_ACCESS_KEY_ID=$(MINIO_ACCESS_KEY) AWS_SECRET_ACCESS_KEY=$(MINIO_SECRET_KEY)
REGISTRY_HOST ?= localhost:5001
REGISTRY_COMPOSE ?= docker compose -f backend/registry/compose.yaml
DEMO_APP_NAME ?= terraform-practice/hello-app
DEMO_APP_TAG ?= 0.1.0-local
DEMO_IMAGE ?= $(REGISTRY_HOST)/$(DEMO_APP_NAME):$(DEMO_APP_TAG)

.PHONY: backend-up backend-down backend-logs backend-objects backend-migrate registry-up registry-down registry-logs registry-catalog registry-tags demo-image-build demo-image-push demo-image init fmt validate plan plan-file apply destroy output state ps services pvc ingress ingress-controller argocd argocd-apps argocd-app argocd-root-app argocd-app-values argocd-password hello-app helm-status port-forward-prometheus port-forward-grafana port-forward-alertmanager urls

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

registry-up:
	$(REGISTRY_COMPOSE) up -d

registry-down:
	$(REGISTRY_COMPOSE) down

registry-logs:
	$(REGISTRY_COMPOSE) logs -f registry

registry-catalog:
	curl -fsS http://$(REGISTRY_HOST)/v2/_catalog; echo

registry-tags:
	curl -fsS http://$(REGISTRY_HOST)/v2/$(DEMO_APP_NAME)/tags/list; echo

demo-image-build:
	docker build -t $(DEMO_IMAGE) apps/hello-app

demo-image-push:
	docker push $(DEMO_IMAGE)

demo-image: registry-up demo-image-build demo-image-push

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

argocd:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get pods,svc,ingress

argocd-apps:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get applications.argoproj.io

argocd-app:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get application $(ARGOCD_APP) -o wide

argocd-root-app:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get application $(ARGOCD_ROOT_APP) -o wide

argocd-app-values:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get application $(ARGOCD_APP) -o jsonpath='{.spec.source.helm.values}'

argocd-password:
	kubectl --context $(CONTEXT) -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

hello-app:
	kubectl --context $(CONTEXT) -n $(HELLO_APP_NAMESPACE) get pods,svc,ingress

helm-status:
	helm status argocd -n $(ARGOCD_NAMESPACE)
	helm status ingress-nginx -n ingress-nginx

port-forward-prometheus:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/prometheus-operated 9091:9090

port-forward-grafana:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/$(RELEASE)-grafana 3001:3000

port-forward-alertmanager:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) port-forward svc/alertmanager-operated 9094:9093

urls:
	@echo "Argo CD:      http://argocd.localhost"
	@echo "Hello App:    http://hello.localhost"
	@echo "Grafana:      http://grafana.localhost"
	@echo "Prometheus:   http://prometheus.localhost"
	@echo "Alertmanager: http://alertmanager.localhost"
