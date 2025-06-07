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
  description = "External port on the Docker LXC host that will be mapped to the WEB application container"
  type        = number
  default     = 8080 # Access will be via http://[DOCKER_ZEROTIER_IP_ADDRESS]:8080
}

# --- Resources ---
# 1. Build Docker Image
resource "docker_image" "iot_web_app_image" {
  # Image name and tag
  name = "iot-web-app:latest"

  build {
    # Path to the directory where the Dockerfile and application code (`app.py`) are located.
    # The path is relative to this main.tf file's location.
    context = "${path.root}/../app"

    # Add a build argument that depends on the content of app.py.
    # When app.py changes, its hash will change, and Terraform will know
    # that the image needs to be rebuilt.
    build_arg = {
      APP_CONTENT_HASH = filesha256("${path.root}/../app/app.py")
    }
    # dockerfile = "Dockerfile"
    # extra_options = ["--no-cache"]
  }

  # Prevents Terraform from deleting the image from the local Docker cache
  # when the resource is removed from the code/state.
  # If you want `terraform destroy` to attempt to delete the image, set this to `false`.
  keep_locally = true
}

# 2. Run Docker Container
# This resource will run a container using the previously built image.
resource "docker_container" "iot_web_server_container" {
  # Container name in the Docker environment
  name  = "iot-data-viewer-web"

  # Specifies the ID of the image built in the previous step.
  # Using .image_id ensures the container is recreated if the image changes.
  image = docker_image.iot_web_app_image.image_id

  # Port mapping:
  # internal - the port the application listens on *inside* the container (from Dockerfile EXPOSE)
  # external - the port that will be opened on the Docker *host* machine
  ports {
    internal = 5000
    external = var.web_app_external_port
  }

  # Environment variables that will be passed to the container.
  # The application (`app.py`) will use these to connect to MySQL.
  env = [
    "DB_HOST=${var.db_host}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=${var.db_name}",
    # Additional variables if needed, for example:
    "FLASK_ENV=production" # Can be set to 'development' for debugging
  ]

  # Container restart policy.
  # "unless-stopped" - will restart the container if it stops, unless manually stopped.
  # Other options: "no", "always", "on-failure"
  restart = "unless-stopped"

  # Adds the container to the default 'bridge' network in Docker.
  # Since MySQL is in another LXC container but on the same ZeroTier network,
  # connection via IP address should work.
  # If a specific Docker network were needed, it would be defined separately with `docker_network`
  # and added here with `networks_advanced`.

  # Ensures that this resource is created or updated only *after*
  # the `docker_image.iot_web_app_image` resource has been successfully created/updated.
  depends_on = [
    docker_image.iot_web_app_image
  ]
}

# --- Outputs ---
# We output the URL address where the web page will be available after successful deployment.
output "web_application_url" {
  description = "URL where the IoT data viewer web page is available"
  # We use the known Docker LXC IP address directly
  value       = "http://[DOCKER_ZEROTIER_IP_ADDRESS]:${var.web_app_external_port}"
}
