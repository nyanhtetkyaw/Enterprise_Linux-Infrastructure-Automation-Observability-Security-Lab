terraform {
  required_providers {
    podman = {
      source  = "blechschmidt/podman"
      version = "~> 0.5"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "podman" {
  host = "unix:///run/podman/podman.sock"
}

resource "podman_network" "lab_net" {
  name = "labnet"

  driver = "bridge"
}


# Vault
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "vault" {
  name  = "vault"
  image = "docker.io/hashicorp/vault:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 8200
    external = 8200
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/vault/data"
    container_path = "/vault/data"
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/vault"
    container_path = "/vault/config"
    read_only      = true
  }

  command = [
    "server"
  ]

  depends_on = [
    podman_network.management
  ]
}


# HTTPD application servers
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "httpd_app" {
  count = 2

  name  = "httpd-app-${count.index + 1}"
  image = "docker.io/httpd:2.4"

  networks_advanced {
    name = podman_network.application.name
  }

  networks_advanced {
    name = podman_network.database.name
  }

  ports {
    internal = 80
    external = 8081 + count.index
  }

  volumes {
    host_path      = count.index == 0 ? "/home/ansible/terraform-local/ansible/files/index.html" : "/home/ansible/terraform-local/ansible/files/index1.html"
    container_path = "/usr/local/apache2/htdocs/index.html"
    read_only      = true
  }

  depends_on = [
    podman_network.application,
    podman_network.database
  ]
}


# HAProxy
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "haproxy" {
  name  = "haproxy-lb"
  image = "docker.io/eeacms/haproxy:latest"

  networks_advanced {
    name = podman_network.dmz.name
  }

  networks_advanced {
    name = podman_network.application.name

  }

  ports {
    internal = 8080
    external = 8080
  }

  ports {
    internal = 8404
    external = 8404
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/haproxy.cfg"
    container_path = "/usr/local/etc/haproxy/haproxy.cfg"
    read_only      = true
  }
}



# Jenkins
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "jenkins" {
  name  = "jenkins"
  image = "docker.io/jenkins/jenkins:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  networks_advanced {
    name = podman_network.application.name
  }

  ports {
    internal = 8080
    external = 8088
  }

  ports {
    internal = 50000
    external = 50000
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/jenkins/data"
    container_path = "/var/jenkins_home"
  }

  volumes {
    host_path      = "/run/podman/podman.sock"
    container_path = "/run/podman/podman.sock"
  }

  depends_on = [
    podman_network.management,
    podman_network.application
  ]
}



# SonarQube
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "sonarqube" {
  name  = "sonarqube"
  image = "docker.io/library/sonarqube:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 9000
    external = 9000
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/sonarqube/data"
    container_path = "/opt/sonarqube/data"
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/sonarqube/extensions"
    container_path = "/opt/sonarqube/extensions"
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/sonarqube/logs"
    container_path = "/opt/sonarqube/logs"
  }

  depends_on = [
    podman_network.management
  ]
}


# Caddy
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "caddy" {
  name  = "caddy-edge"
  image = "docker.io/library/caddy:2"

  networks_advanced {
    name = podman_network.dmz.name
  }

  networks_advanced {
    name = podman_network.application.name
  }

  depends_on = [
    podman_container.haproxy
  ]

  ports {
    internal = 80
    external = 8880
  }

  ports {
    internal = 443
    external = 8443
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/Caddyfile"
    container_path = "/etc/caddy/Caddyfile"
  }
}


# Prometheus
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "prometheus" {
  name  = "prometheus"
  image = "quay.io/prometheus/prometheus:v3.5.0"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/prometheus/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }
}


# Grafana
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++


resource "podman_container" "grafana" {
  name  = "grafana"
  image = "docker.io/grafana/grafana"

  networks_advanced {
    name = podman_network.management.name
  }

  depends_on = [
    podman_container.prometheus
  ]

  ports {
    internal = 3000
    external = 3000
  }
}


# cAdvisor
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "cadvisor" {
  name  = "cadvisor"
  image = "ghcr.io/google/cadvisor:v0.53.0"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 8080
    external = 8085
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
  }

  volumes {
    host_path      = "/dev/disk"
    container_path = "/dev/disk"
    read_only      = true
  }

  privileged = true
}


# k6
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "k6" {
  name  = "k6"
  image = "docker.io/grafana/k6:latest"

  entrypoint = [
    "/bin/sh",
    "-c"
  ]

  command = [
    "sleep infinity"
  ]

  networks_advanced {
    name = podman_network.application.name
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/k6"
    container_path = "/scripts"
    read_only      = true
  }

  depends_on = [
    podman_container.caddy,
    podman_container.haproxy
  ]
}


# Blackbox Exporter
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "blackbox" {
  name  = "blackbox-exporter"
  image = "docker.io/secureimages/blackbox-exporter:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 9115
    external = 9115
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/blackbox/blackbox.yml"
    container_path = "/etc/blackbox_exporter/config.yml"
    read_only      = true
  }

  depends_on = [
    podman_network.management
  ]
}


# Loki
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "loki" {
  name  = "loki"
  image = "docker.io/grafana/loki:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 3100
    external = 3100
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/loki/loki-config.yml"
    container_path = "/etc/loki/loki-config.yml"
    read_only      = true
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/loki/data"
    container_path = "/loki"
  }

  command = [
    "-config.file=/etc/loki/loki-config.yml"
  ]

  depends_on = [
    null_resource.loki_storage
  ]
}


# Node Exporter
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "node_exporter" {
  name  = "node-exporter"
  image = "quay.io/prometheus/node-exporter:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 9100
    external = 9100
  }

  volumes {
    host_path      = "/proc"
    container_path = "/host/proc"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/host/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/"
    container_path = "/host/root"
    read_only      = true
  }

  command = [
    "--path.procfs=/host/proc",
    "--path.sysfs=/host/sys",
    "--path.rootfs=/host/root"
  ]

  depends_on = [
    podman_network.management
  ]
}


# Grafana Alloy
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "alloy" {
  name  = "alloy"
  image = "docker.io/grafana/alloy:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  depends_on = [
    podman_container.loki
  ]

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/alloy/config.alloy"
    container_path = "/etc/alloy/config.alloy"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/containers/storage/overlay-containers"
    container_path = "/var/lib/containers/storage/overlay-containers"
    read_only      = true
  }

  command = [
    "run",
    "/etc/alloy/config.alloy",
    "--server.http.listen-addr=0.0.0.0:12345"
  ]
}


# PostgreSQL
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "postgresql" {
  name  = "postgresql"
  image = "docker.io/bitnami/postgresql:latest"

  networks_advanced {
    name = podman_network.database.name
  }

  env = [
    "POSTGRES_DB=webapp",
    "POSTGRES_USER=webapp",
    "POSTGRES_PASSWORD=ChangeMe-LabOnly-2026"
  ]

  volumes {
    host_path      = "/home/ansible/terraform-local/postgresql/data"
    container_path = "/var/lib/postgresql/data"
  }

  depends_on = [
    podman_network.database
  ]
}


# Alert Manager
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "podman_container" "alertmanager" {
  name  = "alertmanager"
  image = "docker.io/prom/alertmanager:latest"

  networks_advanced {
    name = podman_network.management.name
  }

  ports {
    internal = 9093
    external = 9093
  }

  volumes {
    host_path      = "/home/ansible/terraform-local/ansible/files/alertmanager/alertmanager.yml"
    container_path = "/etc/alertmanager/alertmanager.yml"
    read_only      = true
  }

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml",
    "--storage.path=/alertmanager"
  ]

  depends_on = [
    podman_network.management
  ]
}



# Adding Loki storage
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

resource "null_resource" "loki_storage" {
  provisioner "local-exec" {
    command = "ansible-playbook -i localhost, -c local ansible/files/loki_storage.yml"
  }
}
