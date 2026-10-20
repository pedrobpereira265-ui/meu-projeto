
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Imagem do Nginx
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

# Nova rede Docker
resource "docker_network" "monitoring" {
  name = "monitoring-net"
}

# Container web atualizado
resource "docker_container" "web" {
  name  = "meu-container-web"
image = docker_image.nginx.image_id

  ports {
    internal = 80 external = 8080
  }

  # Mantém os arquivos do site
  volumes {
    host_path      = "${path.cwd}/site"
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }

  # Conecta o Nginx à nova rede
  networks_advanced {
    name = docker_network.monitoring.name
  }
}

# Volume persistente do PostgreSQL
resource "docker_volume" "db_data" {
  name = "meu-projeto-db-data"
}

# Imagem do PostgreSQL
resource "docker_image" "postgres" {
  name = "postgres:16"
}

# Container do banco de dados
resource "docker_container" "db" {
  name  = "meu-container-db"
  image = docker_image.postgres.image_id

  env = ["POSTGRES_PASSWORD=senha123"]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }
}

resource "docker_container" "cadvisor" {
  name       = "cadvisor"
  image      = "gcr.io/cadvisor/cadvisor:latest"
  privileged = true
  ports {
    internal = 8080
    external = 8081
  }
  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }
  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
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
  volumes {
    host_path      = "/dev/disk"
    container_path = "/dev/disk"
    read_only      = true
  }
  devices {
    host_path      = "/dev/kmsg"
    container_path = "/dev/kmsg"
    permissions    = "rwm"
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id
  ports {
    internal = 9090
    external = 9090
  }
  volumes {
    host_path      = "${path.cwd}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}