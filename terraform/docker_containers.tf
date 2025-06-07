terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      # It's recommended to specify a concrete version for stability
      version = "~> 3.0.1"
    }
  }
}

# --- Docker Provider Configuration ---
# WARNING: tcp://... without TLS is not secure! Consider using TLS in production.
provider "docker" {
  host = "tcp://[DOCKER_ZEROTIER_IP_ADDRESS]:2375"
  # If you were using TLS, you would specify paths to certificates here:
  # host          = "tcp://[DOCKER_ZEROTIER_IP_ADDRESS]:2376"
  # ca_material   = file("path/to/ca.pem")
  # cert_material = file("path/to/cert.pem")
  # key_material  = file("path/to/key.pem")
}

# --- Variables ---
variable "db_host" {
  description = "MySQL database host IP address (from ZeroTier)"
  type        = string
  default     = "[MYSQL_ZEROTIER_IP_ADDRESS]"
}

variable "db_user" {
  description = "MySQL username"
  type        = string
  default     = "iot_user"
}

variable "db_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
  default     = "######"
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "iot"
}

variable "web_app_external_port" {
  description = "External port on the Docker LXC host for the web app container"
  type        = number
  default     = 8080
}

variable "grafana_external_port" {
  description = "External port on the Docker LXC host for the Grafana container"
  type        = number
  default     = 3000
}

variable "grafana_admin_password" {
  description = "Password for the Grafana 'admin' user"
  type        = string
  sensitive   = true
  default     = "######"
}

# --- Resources ---

# 1. Build Docker Image for the Web App
resource "docker_image" "iot_web_app_image" {
  # Image name and tag
  name = "iot-web-app:latest"

  build {
    # Path to the directory where the Dockerfile and application code (`app.py`) are located.
    # The path is relative to this .tf file's location.
    context = "${path.root}/../app"

    # Add a build argument that depends on the content of app.py.
    # When app.py changes, its hash will change, and Terraform will know
    # that the image needs to be rebuilt.
    build_arg = {
      APP_CONTENT_HASH = filesha256("${path.root}/../app/app.py")
    }
  }

  # Prevents Terraform from deleting the image from the local Docker cache
  # when the resource is removed from the code/state.
  keep_locally = true
}

# 2. Run Docker Container for the Web App
resource "docker_container" "iot_web_server_container" {
  # Container name in the Docker environment
  name  = "iot-data-viewer-web"

  # Use the ID of the image built in the previous step.
  image = docker_image.iot_web_app_image.image_id

  # Port mapping: internal -> external
  ports {
    internal = 5000
    external = var.web_app_external_port
  }

  # Environment variables to be passed to the container.
  env = [
    "DB_HOST=${var.db_host}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=${var.db_name}",
    # Additional variables, e.g., for debugging
    "FLASK_ENV=production"
  ]

  # Container restart policy
  restart = "unless-stopped"

  # Ensures this resource is created only after the image is built.
  depends_on = [
    docker_image.iot_web_app_image
  ]
}

# --- Grafana Resources ---
# Create a Docker Volume for Grafana's persistent data
resource "docker_volume" "grafana_data_volume" {
  name = "grafana-storage"
}

# Pull the Grafana Docker Image
resource "docker_image" "grafana_image" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

# Run the Docker Container for Grafana
resource "docker_container" "grafana_container" {
  name  = "grafana-server"
  image = docker_image.grafana_image.image_id

  ports {
    internal = 3000
    external = var.grafana_external_port
  }

  volumes {
    volume_name    = docker_volume.grafana_data_volume.name
    container_path = "/var/lib/grafana"
  }

  env = [
    "GRAFANA_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
  ]

  restart = "unless-stopped"

  depends_on = [
    docker_volume.grafana_data_volume,
    docker_image.grafana_image
  ]
}

# --- Outputs ---
# Output the URL for the web app
output "web_application_url" {
  description = "URL for the IoT data viewer web page"
  value       = "http://[DOCKER_ZEROTIER_IP_ADDRESS]:${var.web_app_external_port}"
}

# Output the URL for Grafana
output "grafana_url" {
  description = "URL for the Grafana interface"
  value       = "http://[DOCKER_ZEROTIER_IP_ADDRESS]:${var.grafana_external_port}"
}
