resource "proxmox_lxc" "gitlab" {
  vmid         = 100
  target_node  = "pve-iac"
  hostname     = "gitlab-container"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "######"
  unprivileged = true
  start        = true
  memory       = 8192
  cores        = 4
  onboot       = true

  rootfs {
    storage = "IaC-Storage-3"
    size    = "30G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}

resource "proxmox_lxc" "docker" {
  vmid         = 101
  target_node  = "pve-iac"
  hostname     = "docker-container"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "######"
  unprivileged = true
  start        = true
  memory       = 4096
  cores        = 2
  onboot       = true

  # Parameters to allow Docker inside an unprivileged LXC container
  features {
    nesting = 1
    keyctl  = 1
  }

  rootfs {
    storage = "IaC-Storage-3"
    size    = "10G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}

resource "proxmox_lxc" "mysql" {
  vmid         = 102
  target_node  = "pve-iac"
  hostname     = "mysql-container"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "######"
  unprivileged = true
  start        = true
  memory       = 4096
  cores        = 2
  onboot       = true

  rootfs {
    storage = "IaC-Storage-3"
    size    = "10G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}
