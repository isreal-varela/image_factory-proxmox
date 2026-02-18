# image_factory-proxmox

```
.
├── README.md                # Documentation and setup guide
├── build.sh                 # Wrapper script to run builds with flags
├── builds/
│   ├── main.pkr.hcl         # Core logic (source & build blocks)
│   └── variables.pkr.hcl    # All variable declarations
├── http/
│   ├── rocky-9-ks.cfg       # Rocky 9 Kickstart
│   ├── rhel-9-ks.cfg        # RHEL 9 Kickstart
│   └── common-post.sh       # Shared post-install scripts - Currently Empty
├── scripts/
│   └── common_setup.sh      # Packer provisioner script (cleanup/prep) 
└── vars/
    ├── lab.pkrvars.hcl      # Infrastructure config (Git tracked)
    └── secrets.pkrvars.hcl  # Secrets (GIT IGNORED)
```

## Proxmox Image Factory

An automated Packer-based project to build Rocky Linux and RHEL golden images on a Proxmox cluster.

## 🚀 Features
* **Multi-Distro Support**: Easily switch between Rocky and RHEL.
* **Hardware Profiles**: Choice of `small`, `medium`, or `large` VM specs.
* **DRY Architecture**: Uses HCL locals and maps to prevent code duplication.
* **Secure**: Sensitive credentials are kept in a separate, ignored variables file.

## 🛠  Prerequisites
* **Proxmox VE Cluster** (with API Token)
* **Packer 1.15.0+** installed on the build host
* **Firewall Access**: Port `8800` open on the build host for HTTP kickstart delivery.

## Infra Configuration
You will need to update lab vars if taking this to another ProxMox cluster

### vars/lab.pkrvars.hcl Template
```hcl
# Proxmox Connection
proxmox_url = "https://192.168.1.11:8006/api2/json"

# Lab Environment Settings
proxmox_node     = "pve-01"
proxmox_storage  = "local-lvm"
proxmox_network  = "vmbr0"

# Default Build Settings (Overridden by build.sh)
distro  = "rocky"
version = "9"
size    = "small"
```

## 📁 Secrets Configuration
This project uses a file called `vars/secrets.pkrvars.hcl` which is **git-ignored** for security. If you need to recreate it, use the following template:

### secrets.pkrvars.hcl Template
```hcl
# Proxmox API Authentication
proxmox_api_token_id     = "user@pam!token"
proxmox_api_token_secret = "YOUR_SECRET_TOKEN_HERE"

# OS Provisioning Credentials (must match your Kickstart settings)
ssh_username = "your_user"
ssh_password = "YOUR_SAFE_PASSWORD"
```
## 🏗  Usage

1. Build Default (Rocky 9 - Small)
```
./build.sh
```
2. Build Specific Configuration
```
./build.sh -d rhel -v 9 -s large
```
Options:
```
-d: Distro (rocky or rhel)

-v: Version (8 or 9)

-s: Size (small, medium, or large)
```
## 🧹 Cleanup & Maintenance
The scripts/common_setup.sh runs automatically to:

Remove unique machine IDs.

Clear shell history and dnf cache.

Prepare Cloud-Init for the first boot.

---

## Important: `.gitignore`
To ensure that `secrets.pkrvars.hcl` never accidentally ends up on GitHub, create a file named `.gitignore` in your project root with these lines:

```text
# Ignore sensitive variable files
vars/secrets.pkrvars.hcl
*.pkrvars.hcl

# Ignore Packer cache and logs
.packer/
packer_cache/
crash.log

# Ignore OS artifacts
*.iso
