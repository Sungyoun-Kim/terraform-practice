resource "local_file" "prometheus_config" {
  filename = "${path.module}/generated/prometheus/prometheus.yml"

  content = templatefile("${path.module}/templates/prometheus.yml.tftpl", {
    scrape_interval     = var.scrape_interval
    evaluation_interval = var.evaluation_interval
    enable_cadvisor     = var.enable_cadvisor
  })
}

resource "local_file" "prometheus_rules" {
  filename = "${path.module}/generated/prometheus/rules/learning.rules.yml"
  content  = templatefile("${path.module}/templates/learning.rules.yml.tftpl", {})
}

resource "docker_network" "monitoring" {
  name = local.network_name
}

resource "docker_volume" "prometheus_data" {
  name = local.volume_names.prometheus
}

resource "docker_volume" "grafana_data" {
  name = local.volume_names.grafana
}

resource "docker_volume" "alertmanager_data" {
  name = local.volume_names.alertmanager
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:${var.prometheus_version}"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:${var.grafana_version}"
  keep_locally = true
}

resource "docker_image" "alertmanager" {
  name         = "prom/alertmanager:${var.alertmanager_version}"
  keep_locally = true
}

resource "docker_image" "node_exporter" {
  name         = "prom/node-exporter:${var.node_exporter_version}"
  keep_locally = true
}

resource "docker_image" "cadvisor" {
  count        = var.enable_cadvisor ? 1 : 0
  name         = "gcr.io/cadvisor/cadvisor:${var.cadvisor_version}"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name  = local.container_names.prometheus
  image = docker_image.prometheus.image_id

  restart = "unless-stopped"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles",
    "--web.enable-lifecycle",
  ]

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["prometheus"]
  }

  volumes {
    host_path      = abspath("${path.module}/generated/prometheus")
    container_path = "/etc/prometheus"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  depends_on = [
    local_file.prometheus_config,
    local_file.prometheus_rules,
    docker_container.alertmanager,
    docker_container.node_exporter,
  ]

  lifecycle {
    replace_triggered_by = [
      local_file.prometheus_config,
      local_file.prometheus_rules,
    ]
  }
}

resource "docker_container" "grafana" {
  name  = local.container_names.grafana
  image = docker_image.grafana.image_id

  restart = "unless-stopped"

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_ANALYTICS_REPORTING_ENABLED=false",
    "GF_ANALYTICS_CHECK_FOR_UPDATES=false",
  ]

  ports {
    internal = 3000
    external = var.grafana_port
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["grafana"]
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = abspath("${path.module}/config/grafana/provisioning")
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${path.module}/config/grafana/dashboards")
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }

  depends_on = [
    docker_container.prometheus,
  ]
}

resource "docker_container" "alertmanager" {
  name  = local.container_names.alertmanager
  image = docker_image.alertmanager.image_id

  restart = "unless-stopped"

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml",
    "--storage.path=/alertmanager",
  ]

  ports {
    internal = 9093
    external = var.alertmanager_port
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["alertmanager"]
  }

  volumes {
    host_path      = abspath("${path.module}/config/alertmanager")
    container_path = "/etc/alertmanager"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.alertmanager_data.name
    container_path = "/alertmanager"
  }
}

resource "docker_container" "node_exporter" {
  name  = local.container_names.node_exporter
  image = docker_image.node_exporter.image_id

  restart = "unless-stopped"

  ports {
    internal = 9100
    external = var.node_exporter_port
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["node-exporter"]
  }
}

resource "docker_container" "cadvisor" {
  count = var.enable_cadvisor ? 1 : 0

  name       = local.container_names.cadvisor
  image      = docker_image.cadvisor[0].image_id
  privileged = true
  restart    = "unless-stopped"

  command = [
    "--housekeeping_interval=10s",
    "--docker_only=true",
  ]

  ports {
    internal = 8080
    external = var.cadvisor_port
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["cadvisor"]
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }
}
