#!/bin/bash

# HTTP Repository Setup Script for RHEL/CentOS
# Created for learning client-side .repo configuration.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Starting HTTP Repository Setup..."

# 1. Install required packages
# httpd: web server
# createrepo_c: tool to generate repo metadata
# dnf-plugins-core: provides 'dnf download' command
echo "Installing utilities..."
dnf install -y httpd createrepo_c dnf-plugins-core

# 2. Create Repo Directory
REPO_DIR="/var/www/html/myrepo"
echo "Creating repository directory at $REPO_DIR..."
mkdir -p "$REPO_DIR"

# 3. Download Sample Packages
echo "Downloading sample packages..."
# downloading 'tree', 'tmux', 'zsh' as examples
# --resolve fetches dependencies too
dnf download --resolve --destdir="$REPO_DIR" tree tmux zsh

# 4. Generate Metadata
echo "Generating repository metadata..."
createrepo "$REPO_DIR"

# 5. Start Web Server
echo "Starting Apache..."
systemctl enable --now httpd

# 6. Configure Firewall
echo "Configuring firewall..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --reload
    echo "Firewall rules updated."
else
    echo "Firewalld is not running. Skipping."
fi

# 7. Verification
PUBLIC_IP=$(hostname -I | awk '{print $1}')
echo "============================================"
echo "Setup Complete!"
echo "Repository URL: http://$PUBLIC_IP/myrepo"
echo "============================================"
echo "To test on client, create /etc/yum.repos.d/myrepo.repo with:"
echo "[myrepo]"
echo "name=My Local Repo"
echo "baseurl=http://$PUBLIC_IP/myrepo"
echo "enabled=1"
echo "gpgcheck=0"
