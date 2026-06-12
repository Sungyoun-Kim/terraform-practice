.PHONY: init fmt validate plan apply destroy output ps logs-prometheus logs-grafana logs-alertmanager urls

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
	docker ps --filter "name=tf-prometheus-stack"

logs-prometheus:
	docker logs tf-prometheus-stack-prometheus

logs-grafana:
	docker logs tf-prometheus-stack-grafana

logs-alertmanager:
	docker logs tf-prometheus-stack-alertmanager

urls:
	@echo "Prometheus:   http://localhost:9090"
	@echo "Grafana:      http://localhost:3000"
	@echo "Alertmanager: http://localhost:9093"
