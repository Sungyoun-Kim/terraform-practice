CONTEXT ?= docker-desktop
NAMESPACE ?= monitoring-helm
RELEASE ?= prometheus-stack

.PHONY: init fmt validate plan plan-file apply destroy output state ps services pvc ingress ingress-controller helm-status helm-values helm-manifest port-forward-prometheus port-forward-grafana port-forward-alertmanager urls

init:
	terraform init

fmt:
	terraform fmt -recursive

validate:
	terraform fmt -check -recursive
	terraform validate

plan:
	terraform plan

plan-file:
	terraform plan -out=plan.tfplan
	terraform show -no-color plan.tfplan > plan.txt

apply:
	terraform apply

destroy:
	terraform destroy

output:
	terraform output

state:
	terraform state list

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
