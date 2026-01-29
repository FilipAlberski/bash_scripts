#!/bin/bash

# NFS Server Setup Script for RHEL/CentOS/Fedora
# Created for learning autofs on the client side.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Starting NFS Server Setup..."

# 1. Install NFS Utilities
echo "Installing nfs-utils..."
dnf install -y nfs-utils

# 2. Create Shared Directories
echo "Creating shared directories..."
mkdir -p /srv/nfs/share1
mkdir -p /srv/nfs/share2
mkdir -p /srv/nfs/isos
mkdir -p /srv/nfs/homes/user1
mkdir -p /srv/nfs/homes/user2

# 3. Create Dummy Content
echo "Creating dummy content for testing..."
echo "This is a read-write share." > /srv/nfs/share1/rw_test_file.txt
echo "This is a read-only share." > /srv/nfs/share2/ro_test_file.txt
echo "ISO image simulation" > /srv/nfs/isos/fake_distro.iso
echo "Home directory for user1" > /srv/nfs/homes/user1/file.txt
echo "Home directory for user2" > /srv/nfs/homes/user2/file.txt

# 4. Set Permissions
# Setting permissive permissions for share1 to allow ease of writing during tests
chmod 777 /srv/nfs/share1

# 5. Configure Exports
echo "Configuring /etc/exports..."
# Backup existing exports
cp /etc/exports /etc/exports.bak.$(date +%F_%T)

cat <<EOF > /etc/exports
# NFS Exports for Autofs Learning
/srv/nfs/share1  *(rw,sync,no_root_squash,no_all_squash,insecure)
/srv/nfs/share2  *(ro,sync,no_root_squash,no_all_squash,insecure)
/srv/nfs/isos    *(ro,sync,no_root_squash,no_all_squash,insecure)
/srv/nfs/homes   *(rw,sync,no_root_squash,no_all_squash,insecure)
EOF

# 6. Enable and Start Services
echo "Starting NFS services..."
systemctl enable --now nfs-server

# 7. Configure Firewall
echo "Configuring firewall..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=nfs
    firewall-cmd --permanent --add-service=mountd
    firewall-cmd --permanent --add-service=rpc-bind
    firewall-cmd --reload
    echo "Firewall rules updated."
else
    echo "Firewalld is not running. Skipping firewall configuration."
fi

# 8. Export Shares
echo "Exporting shares..."
exportfs -r

# 9. Verification
echo "Setup Complete. Current Exports:"
showmount -e localhost

echo ""
echo "You can now verify from your client machine."
