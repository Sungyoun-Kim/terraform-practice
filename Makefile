CONTEXT ?= docker-desktop
NAMESPACE ?= monitoring-helm
RELEASE ?= prometheus-stack
ARGOCD_NAMESPACE ?= argocd
ARGOCD_APP ?= kube-prometheus-stack
ARGOCD_ROOT_APP ?= terraform-practice-root
HELLO_APP_NAMESPACE ?= hello-app
HELLO_APP_ENVIRONMENTS ?= dev staging prod
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
VAULT_COMPOSE ?= docker compose -f backend/vault/compose.yaml
VAULT_CONTAINER ?= terraform-practice-vault
VAULT_ADDR ?= http://127.0.0.1:8200
VAULT_TOKEN ?= root
VAULT_SECRET_PATH ?= secret/hello-app
VAULT_SECRET_MESSAGE ?= hello from local Vault
VAULT_SECRET_API_KEY ?= local-vault-api-key
VAULT_MONITORING_SECRET_PATH ?= secret/monitoring/grafana-admin
GRAFANA_ADMIN_USER ?= admin
GRAFANA_ADMIN_PASSWORD ?= admin

.PHONY: backend-up backend-down backend-logs backend-objects backend-migrate registry-up registry-down registry-logs registry-catalog registry-tags demo-image-build demo-image-push demo-image vault-up vault-down vault-logs vault-status vault-wait vault-seed vault-token-secret vault-bootstrap vault-read vault-read-monitoring init fmt validate plan plan-file apply destroy output state ps services pvc ingress ingress-controller argocd argocd-apps argocd-app argocd-root-app argocd-app-values argocd-password hello-app hello-envs hello-secret hello-env-secrets monitoring-secret external-secrets helm-status port-forward-prometheus port-forward-grafana port-forward-alertmanager urls

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

vault-up:
	$(VAULT_COMPOSE) up -d

vault-down:
	$(VAULT_COMPOSE) down

vault-logs:
	$(VAULT_COMPOSE) logs -f vault

vault-status:
	docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault status

vault-wait:
	@for i in $$(seq 1 30); do \
		if docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault status >/dev/null 2>&1; then \
			exit 0; \
		fi; \
		sleep 1; \
	done; \
	echo "Vault did not become ready in time" >&2; \
	exit 1

vault-seed: vault-wait
	docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault kv put $(VAULT_SECRET_PATH) message="$(VAULT_SECRET_MESSAGE)" api_key="$(VAULT_SECRET_API_KEY)"
	docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault kv put $(VAULT_MONITORING_SECRET_PATH) admin-user="$(GRAFANA_ADMIN_USER)" admin-password="$(GRAFANA_ADMIN_PASSWORD)"
	@for env in $(HELLO_APP_ENVIRONMENTS); do \
		docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault kv put secret/hello-app/$$env message="hello from local Vault ($$env)" api_key="local-vault-api-key-$$env"; \
	done

vault-token-secret:
	kubectl --context $(CONTEXT) create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -
	kubectl --context $(CONTEXT) -n $(NAMESPACE) create secret generic vault-token --from-literal=token=$(VAULT_TOKEN) --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -
	kubectl --context $(CONTEXT) create namespace $(HELLO_APP_NAMESPACE) --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -
	kubectl --context $(CONTEXT) -n $(HELLO_APP_NAMESPACE) create secret generic vault-token --from-literal=token=$(VAULT_TOKEN) --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -
	@for env in $(HELLO_APP_ENVIRONMENTS); do \
		namespace="$(HELLO_APP_NAMESPACE)-$$env"; \
		kubectl --context $(CONTEXT) create namespace $$namespace --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -; \
		kubectl --context $(CONTEXT) -n $$namespace create secret generic vault-token --from-literal=token=$(VAULT_TOKEN) --dry-run=client -o yaml | kubectl --context $(CONTEXT) apply -f -; \
	done

vault-bootstrap: vault-up vault-seed vault-token-secret

vault-read:
	docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault kv get $(VAULT_SECRET_PATH)

vault-read-monitoring:
	docker exec -e VAULT_ADDR=$(VAULT_ADDR) -e VAULT_TOKEN=$(VAULT_TOKEN) $(VAULT_CONTAINER) vault kv get $(VAULT_MONITORING_SECRET_PATH)

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

hello-envs:
	@for env in $(HELLO_APP_ENVIRONMENTS); do \
		namespace="$(HELLO_APP_NAMESPACE)-$$env"; \
		echo "== $$namespace =="; \
		kubectl --context $(CONTEXT) -n $$namespace get pods,svc,ingress; \
	done

hello-secret:
	kubectl --context $(CONTEXT) -n $(HELLO_APP_NAMESPACE) get secret hello-app-secret -o yaml

hello-env-secrets:
	@for env in $(HELLO_APP_ENVIRONMENTS); do \
		namespace="$(HELLO_APP_NAMESPACE)-$$env"; \
		echo "== $$namespace =="; \
		kubectl --context $(CONTEXT) -n $$namespace get secretstore,externalsecret; \
		kubectl --context $(CONTEXT) -n $$namespace get secret hello-app-secret; \
	done

monitoring-secret:
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get secretstore,externalsecret
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get secret prometheus-stack-grafana-admin

external-secrets:
	kubectl --context $(CONTEXT) -n external-secrets get pods
	kubectl --context $(CONTEXT) -n $(NAMESPACE) get secretstore,externalsecret
	kubectl --context $(CONTEXT) -n $(HELLO_APP_NAMESPACE) get secretstore,externalsecret

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
	@echo "Hello Dev:    http://hello-dev.localhost"
	@echo "Hello Stg:    http://hello-staging.localhost"
	@echo "Hello Prod:   http://hello-prod.localhost"
	@echo "Grafana:      http://grafana.localhost"
	@echo "Prometheus:   http://prometheus.localhost"
	@echo "Alertmanager: http://alertmanager.localhost"
