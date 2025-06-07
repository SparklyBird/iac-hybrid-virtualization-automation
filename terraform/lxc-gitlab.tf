terraform {
  required_providers {
    proxmox = {
      source = “Telmate/proxmox”
      version = “2.9.14”
    }
  }
}

provider “proxmox” {
  pm_api_url = “https://[GITLAB_ZEROTIER_IP_ADDRESS]:8006/api2/json”
  pm_user = “root@pam”
  pm_password = “######”
  pm_tls_insecure = true
}

resource “proxmox_lxc” “gitlab” {
  vmid         = 100
  target_node  = “pve-iac”
  hostname     = “gitlab-container”
  ostemplate   = “local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst”
  password     = “######”
  unprivileged = true
  start        = true
  memory       = 8192
  cores        = 4
  tty          = 2
  cmode        = “tty”
  console      = true
  cpuunits     = 1024
  cpulimit     = 0
  swap         = 0
  onboot       = true

  rootfs {
    storage = “IaC-Storage-3”
    size    = “30G”
  }

  network {
    name   = “eth0”
    bridge = “vmbr0”
    ip     = “dhcp”
  }
}
