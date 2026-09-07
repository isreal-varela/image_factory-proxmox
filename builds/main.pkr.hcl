packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

locals {
  # Hardware Profiles (DRY sizing)
  sizes = {
    "small"  = { cores = 1, memory = 2048, disk = "20G" }
    "medium" = { cores = 2, memory = 4096, disk = "40G" }
    "large"  = { cores = 4, memory = 8192, disk = "80G" }
  }

  # ISO Mapping
  iso_map = {
    "rocky-9"  = "local:iso/Rocky-9.7-x86_64-dvd.iso"
    "rocky-10" = "local:iso/Rocky-10.1-x86_64-dvd1.iso"
    "rhel-9"   = "local:iso/rhel-9.6-x86_64-boot.iso"
    "rhel-10"  = "local:iso/rhel-10.2-x86_64-dvd.iso"
  }

  # Determine final values
  current_size = local.sizes[var.size]
  current_iso  = local.iso_map["${var.distro}-${var.version}"]

  # Kickstart URL shared by all boot styles
  ks_url = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.distro}-${var.version}-ks.cfg"

  # Boot command varies by major version:
  #  - EL9 boot ISOs still ship isolinux (BIOS) -> <tab> edits the append line
  #  - EL10 ISOs use GRUB2 even under SeaBIOS   -> `e` edits the entry, <f10> boots
  boot_commands = {
    "9" = [
      "<tab><up> text inst.ks=${local.ks_url} rd.live.check=0<enter><wait>"
    ]
    "10" = [
      "<wait5s>e",
      "<down><down><end>",
      " inst.ks=${local.ks_url} inst.text rd.live.check=0",
      "<f10>"
    ]
  }

  current_boot_command = lookup(local.boot_commands, var.version, local.boot_commands["9"])
}

source "proxmox-iso" "factory" {
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = true
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret

  node = var.proxmox_node

  vm_name              = "${var.distro}-${var.version}-${var.size}"
  template_description = "${var.distro}-${var.version}, generated on ${timestamp()}"

  # Dynamic Hardware from our map
  cores  = local.current_size.cores
  memory = local.current_size.memory

  cpu_type = "host"

  boot_iso {
    type         = "scsi"
    iso_file     = local.current_iso
    unmount      = true
    iso_checksum = "none"
  }

  disks {
    disk_size    = local.current_size.disk
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  scsi_controller = "virtio-scsi-single"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Define the port range for the Kickstart server
  http_port_min  = 8800
  http_port_max  = 8800
  http_directory = "http"

  # Dynamic Kickstart boot command (see local.boot_commands)
  boot_command = local.current_boot_command

  # Proxmox API task timeout (VM stop/start, template conversion) - default 1m is
  # tight on a loaded node; the post-install reboot itself takes ~60-90s.
  task_timeout = "5m"

  # SSH for provisioning
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password # Defined in your Kickstart
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-iso.factory"]

  # Common provisioning for ALL distros
  provisioner "shell" {
    script = "scripts/common_setup.sh"
  }
}
