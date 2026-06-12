.PHONY: init fmt validate plan apply destroy output ps services pvc logs-prometheus logs-grafana logs-alertmanager port-forward-prometheus port-forward-grafana port-forward-alertmanager urls

init:
	terraform init

fmt:
	terraform fmt -recursive

validate:
	terraform fmt -check -recursive
	terraform validate

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

output:
	terraform output

ps:
	kubectl --context docker-desktop -n monitoring get pods

services:
	kubectl --context docker-desktop -n monitoring get svc

pvc:
	kubectl --context docker-desktop -n monitoring get pvc

logs-prometheus:
	kubectl --context docker-desktop -n monitoring logs deploy/prometheus

logs-alertmanager:
	kubectl --context docker-desktop -n monitoring logs deploy/alertmanager

logs-grafana:
	kubectl --context docker-desktop -n monitoring logs deploy/grafana

port-forward-prometheus:
	kubectl --context docker-desktop -n monitoring port-forward svc/prometheus 9090:9090

port-forward-grafana:
	kubectl --context docker-desktop -n monitoring port-forward svc/grafana 3000:3000

port-forward-alertmanager:
	kubectl --context docker-desktop -n monitoring port-forward svc/alertmanager 9093:9093

urls:
	@terraform output prometheus_url
	@terraform output grafana_url
	@terraform output alertmanager_url
