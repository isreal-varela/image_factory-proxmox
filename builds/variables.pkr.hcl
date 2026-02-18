variable "distro" {
  type    = string
  default = "rocky" # can be 'rocky' or 'rhel'
}

variable "version" {
  type    = string
  default = "9"
}

variable "size" {
  type    = string
  default = "small" # small, medium, large
}

# Credentials (populated via pkrvars file)
variable "proxmox_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true # <--- Critically important
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}
