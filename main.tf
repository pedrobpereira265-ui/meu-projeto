
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

# Container web
resource "docker_container" "web" {
  name  = "meu-container-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = "${path.cwd}/site"
    container_path = "/usr/share/nginx/html"
    read_only      = true
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
