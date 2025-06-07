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
# Connects to the Docker daemon on your Docker LXC container.
provider "docker" {
  host = "tcp://[DOCKER_ZEROTIER_IP_ADDRESS]:2375"
  # WARNING: tcp://... without TLS is not secure!
}

# --- Variables ---
variable "grafana_external_port" {
  description = "External port on the Docker LXC host that will be mapped to the Grafana container"
  type        = number
  default     = 3000 # Grafana's default port
}

variable "grafana_admin_password" {
  description = "Password for the Grafana 'admin' user"
  type        = string
  sensitive   = true
  # Insert your chosen Grafana admin password here.
  # If not provided, the default will be used, but it's more secure to change it.
  # You can use your general password or another one.
  default     = "######"
}

variable "grafana_version" {
  description = "Grafana Docker image version (e.g., 'latest', '10.4.1')"
  type        = string
  default     = "latest" # For development, 'latest' can be used, but in production, it's better to specify a concrete version
}

variable "grafana_volume_name" {
  description = "Name for the Docker volume where Grafana will store its configuration and data"
  type        = string
  default     = "grafana-storage" # The name can be changed as desired
}


# --- Resources ---

# 1. Docker Volume for Grafana data
# This is important so that Grafana dashboards, data sources, etc., are preserved
# even if the container is restarted or replaced.
resource "docker_volume" "grafana_data_volume" {
  name = var.grafana_volume_name
  # Labels or driver_opts can be added if needed
}

# 2. Grafana Docker Image
# Ensures the image is available locally on the Docker host.
resource "docker_image" "grafana_image" {
  name         = "grafana/grafana:${var.grafana_version}"
  keep_locally = true # Prevents Terraform from deleting the image from the host on 'destroy'
}

# 3. Grafana Docker Container
resource "docker_container" "grafana_container" {
  # Container name in Docker
  name  = "grafana-server"
  # Uses the ID of the pulled image
  image = docker_image.grafana_image.image_id

  # Port mapping: external (on LXC) -> internal (in container)
  ports {
    # Grafana's default internal port
    internal = 3000
    external = var.grafana_external_port
  }

  # Mounts the created Docker Volume to the /var/lib/grafana folder in the container
  # This is the standard location where Grafana stores its data.
  volumes {
    volume_name    = docker_volume.grafana_data_volume.name
    container_path = "/var/lib/grafana"
  }
 
  # Environment variables for Grafana configuration
  env = [
    # Sets the password for the admin user (username is always 'admin')
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    
    # ----- Other useful options (uncomment if needed) -----
    # More detailed logging (can help with debugging)
    # "GF_LOG_LEVEL=debug",
    
    # Allow anonymous access (DO NOT USE without additional security measures!)
    # "GF_AUTH_ANONYMOUS_ENABLED=true",
    # "GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer", # What the anonymous user can see
    
    # Automatically install plugins on startup (comma-separated)
    # "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource"
  ]

  # Restart policy
  restart = "unless-stopped"

  # Dependencies ensure the correct resource creation order
  depends_on = [
    docker_volume.grafana_data_volume,
    docker_image.grafana_image
  ]
}

# --- Outputs ---
output "grafana_url" {
  description = "URL address for the Grafana interface"
  value       = "http://[DOCKER_ZEROTIER_IP_ADDRESS]:${var.grafana_external_port}"
}

output "grafana_admin_user" {
  description = "Grafana administrator username"
  value       = "admin"
}

output "grafana_admin_password_info" {
  description = "Admin password is set according to the 'grafana_admin_password' variable (manage securely!)"
  value       = "(Password is sensitive and not shown here)"
  sensitive   = true
}

output "grafana_data_volume_name" {
  description = "Name of the created Docker volume for Grafana data"
  value       = docker_volume.grafana_data_volume.name
}
