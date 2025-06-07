# This file defines all the providers required for the project.

terraform {
  required_providers {
    # Provider for Proxmox VE
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
    # Provider for Docker
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Configuration for the Proxmox provider
provider "proxmox" {
  pm_api_url      = "https://[PROXMOX_ZEROTIER_IP_ADDRESS]:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = "######"
  pm_tls_insecure = true
}

# Configuration for the Docker provider
provider "docker" {
  host = "tcp://[DOCKER_ZEROTIER_IP_ADDRESS]:2375"
}
