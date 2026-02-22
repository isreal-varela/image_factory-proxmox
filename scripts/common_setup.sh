#!/bin/bash
set -e

echo ">>> Starting Final Cleanup..."

# 1. Install specific lab tools (if not in Kickstart)
# sudo dnf -y install htop (example)

# 2. Clean up Logs and Cache (Post-update)
echo ">>> Cleaning up dnf cache and logs..."
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo find /var/log -type f -exec truncate -s 0 {} \;

# 3. Universal History Wipe (MUST BE LAST)
echo ">>> Clearing shell history..."
history -c 
#sudo find / /home -name ".bash_history" -exec truncate -s 0 {} \;
#truncate -s 0 ~/.bash_history
