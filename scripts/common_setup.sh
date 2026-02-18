#!/bin/bash
set -e

echo ">>> Starting Golden Image Provisioning..."

# 1. Update the system
echo ">>> Updating the system packages..."
sudo dnf -y update

# 2. Install essential Guest Tools and Cloud-Init
echo ">>> Installing QEMU Guest Agent and Cloud-Init..."
sudo dnf -y install qemu-guest-agent cloud-init cloud-utils-growpart gdisk

# 3. Enable services
echo ">>> Enabling QEMU Guest Agent..."
sudo systemctl enable qemu-guest-agent

echo ">>> Enabling Cloud-Init services..."
sudo systemctl enable cloud-init
sudo systemctl enable cloud-config
sudo systemctl enable cloud-final

# 4. Clean up Network and Hardware Persistence
echo ">>> Removing persistent udev rules..."
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# 5. Reset Machine ID (Crucial for DHCP/Cloning)
# A blank machine-id triggers a new ID generation on first boot
echo ">>> Resetting Machine-ID..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# 6. Clean up Logs and Cache
echo ">>> Cleaning up log files and dnf cache..."
sudo find /var/log -type f -exec truncate -s 0 {} \;
sudo dnf clean all
sudo rm -rf /var/cache/dnf

echo ">>> Clearing shell history for all users..."
# Clear current session history
history -c

# Wipe bash history files for root and all home directories
sudo find / /home -name ".bash_history" -exec truncate -s 0 {} \;
# Wipe the current user's history file explicitly
truncate -s 0 ~/.bash_history

# 7. Zero out the drive (Optional: helps with thin provisioning/compression)
# echo ">>> Zeroing out free space to reduce image size..."
# sudo dd if=/dev/zero of=/EMPTY bs=1M || true
# sudo rm -f /EMPTY

echo ">>> Provisioning Complete. Ready for templating."
