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
  tty          = 2
  cmode        = "tty"
  console      = true
  cpuunits     = 1024
  cpulimit     = 0
  swap         = 0

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
