#!/bin/bash
# Quick start script for VSFTPD/SFTP Ansible deployment

set -e

echo "========================================="
echo "VSFTPD/SFTP Ansible Deployment Setup"
echo "========================================="
echo

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "ERROR: Ansible is not installed."
    echo "Please install Ansible first:"
    echo "  - RHEL/CentOS: sudo yum install ansible"
    echo "  - Ubuntu/Debian: sudo apt install ansible"
    echo "  - Or: pip3 install ansible"
    exit 1
fi

echo "✓ Ansible is installed (version: $(ansible --version | head -1))"
echo

# Check if inventory exists
if [ ! -f "inventory.yml" ]; then
    echo "Creating inventory.yml from example..."
    cp inventory.yml.example inventory.yml
    echo "✓ Created inventory.yml"
    echo
    echo "IMPORTANT: Edit inventory.yml and set your server details!"
    echo
fi

# Check if users.json exists
if [ ! -f "users.json" ]; then
    echo "Creating users.json from example..."
    cp users.json.example users.json
    echo "✓ Created users.json"
    echo
    echo "IMPORTANT: Edit users.json and add your users with hashed passwords!"
    echo "Generate password hash with:"
    echo "  python3 -c 'import crypt; print(crypt.crypt(\"yourpassword\", crypt.mksalt(crypt.METHOD_SHA512)))'"
    echo
fi

# Run syntax check
echo "Checking playbook syntax..."
if ansible-playbook --syntax-check site.yml > /dev/null 2>&1; then
    echo "✓ Playbook syntax is valid"
else
    echo "✗ Playbook syntax check failed"
    ansible-playbook --syntax-check site.yml
    exit 1
fi
echo

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo
echo "Next steps:"
echo "1. Edit inventory.yml with your server details"
echo "2. Edit users.json with your FTP/SFTP users"
echo "3. (Optional) Customize variables in group_vars/all.yml"
echo "4. Test connection: ansible all -m ping"
echo "5. Run playbook: ansible-playbook site.yml"
echo
echo "See README.md for detailed instructions."
