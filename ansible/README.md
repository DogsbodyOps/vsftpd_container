# VSFTPD + SFTP Ansible Playbook

This Ansible playbook replicates the exact same VSFTPD and SFTP configuration used in the [vsftpd_container](https://github.com/DogsbodyServices/vsftpd_container) Docker image for deployment on standard Linux servers.

## 🎯 Overview

This playbook configures a secure FTP/SFTP server with:
- **VSFTPD** for FTP access with passive mode support
- **OpenSSH SFTP** for secure file transfers
- **Chrooted user directories** for security
- **Dynamic user management** from JSON configuration
- **Automated user synchronization** via cron

## 📋 Requirements

### Control Node (where you run Ansible)
- Ansible 2.9 or higher
- Python 3.6 or higher

### Target Servers
- RHEL/CentOS/Rocky Linux 8 or 9
- Ubuntu 20.04 or higher
- Debian 10 or higher
- Python 3 installed
- Sudo/root access

## 🚀 Quick Start

### 1. Clone or Copy This Directory

```bash
# If using from the vsftpd_container repository
cd ansible/

# Or copy the ansible directory to your deployment location
cp -r ansible/ ~/vsftpd-ansible-deployment/
cd ~/vsftpd-ansible-deployment/
```

### 2. Create Your Inventory

```bash
cp inventory.yml.example inventory.yml
```

Edit `inventory.yml` with your server details:

```yaml
all:
  hosts:
    ftp-server-01:
      ansible_host: 192.168.1.100
      ansible_user: your_user
      vsftpd_pasv_address: "ftp.example.com"
```

### 3. Create Users Configuration

Create a `users.json` file with your FTP/SFTP users:

```json
{
  "ftpuser1": "$6$rounds=656000$salt$hashedpassword...",
  "sftpuser1": "$6$rounds=656000$salt$hashedpassword..."
}
```

**Generate password hashes using:**

```bash
# Python method
python3 -c 'import crypt; print(crypt.crypt("yourpassword", crypt.mksalt(crypt.METHOD_SHA512)))'

# Or using mkpasswd (from whois package)
mkpasswd -m sha-512 yourpassword
```

### 4. Run the Playbook

```bash
# Test connection first
ansible all -i inventory.yml -m ping

# Run the playbook
ansible-playbook -i inventory.yml site.yml

# With extra verbosity for debugging
ansible-playbook -i inventory.yml site.yml -v
```

### 5. Deploy Users Configuration

After the playbook runs, copy your `users.json` to the server:

```bash
ansible all -i inventory.yml -m copy -a "src=users.json dest=/etc/vsftpd/users.json mode=0644" --become
```

Then trigger user synchronization:

```bash
ansible all -i inventory.yml -m command -a "/usr/local/bin/update_users.sh" --become
```

## ⚙️ Configuration

### Customizing Variables

You can override default variables in several ways:

#### 1. In the playbook's variable file

Create `group_vars/all.yml`:

```yaml
---
vsftpd_pasv_address: "ftp.example.com"
vsftpd_pasv_min_port: 21000
vsftpd_pasv_max_port: 21050
```

#### 2. In inventory (per host or group)

```yaml
ftp-server-01:
  ansible_host: 192.168.1.100
  vsftpd_pasv_address: "ftp.example.com"
```

#### 3. Via command line

```bash
ansible-playbook -i inventory.yml site.yml -e "vsftpd_pasv_address=ftp.example.com"
```

### Available Variables

See role defaults for complete list:
- `roles/vsftpd/defaults/main.yml` - VSFTPD configuration
- `roles/sshd_sftp/defaults/main.yml` - SSH/SFTP configuration  
- `roles/user_management/defaults/main.yml` - User management settings

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vsftpd_pasv_address` | `127.0.0.1` | Passive mode address (your external IP/domain) |
| `vsftpd_pasv_min_port` | `10000` | Passive mode minimum port |
| `vsftpd_pasv_max_port` | `10250` | Passive mode maximum port |
| `vsftpd_ssl_enable` | `no` | Enable FTPS (requires certificates) |
| `ftp_base_dir` | `/data` | Base directory for user home directories |
| `ftp_user_group` | `simpleftp` | Group for FTP/SFTP users |
| `enable_user_sync_cron` | `yes` | Enable automatic user synchronization |

## 🔐 SSL/TLS Configuration (FTPS)

To enable FTPS:

1. Generate or obtain SSL certificates:

```bash
# Self-signed certificate example
sudo mkdir -p /etc/vsftpd/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/vsftpd/certs/ftps-cert.key \
  -out /etc/vsftpd/certs/ftps-cert.pem
```

2. Set variables to enable SSL:

```yaml
vsftpd_ssl_enable: yes
vsftpd_rsa_cert_file: "/etc/vsftpd/certs/ftps-cert.pem"
vsftpd_rsa_private_key_file: "/etc/vsftpd/certs/ftps-cert.key"
```

3. Re-run the playbook.

## 🧑‍💻 User Management

### User Directory Structure

Each user gets:
```
/data/<username>/
├── in/   # Upload directory (writable by user)
└── out/  # Download directory (writable by user)
```

Root directory `/data/<username>/` is owned by root and read-only.

### Managing Users

Users are managed via `/etc/vsftpd/users.json`:

```json
{
  "user1": "$6$hashed_password",
  "user2": "$6$another_hash"
}
```

**To add/modify users:**

1. Update `users.json` with new users/passwords
2. Copy to server or edit in place
3. Run sync script: `/usr/local/bin/update_users.sh`

**Automatic sync:** Users are automatically synchronized every 30 minutes via cron.

**To manually sync:**
```bash
sudo /usr/local/bin/update_users.sh
```

## 🔥 Firewall Configuration

The playbook automatically configures firewalld if it's running:
- Opens port 21 (FTP)
- Opens port 22 (SSH/SFTP)  
- Opens passive port range (configurable)

If you use a different firewall, configure it manually:

```bash
# For iptables
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 10000:10250 -j ACCEPT
```

## 📊 Logs

- **VSFTPD logs:** Check with `journalctl -u vsftpd`
- **SSH/SFTP logs:** Check with `journalctl -u sshd`
- **User sync logs:** `/var/log/user_updates.log`

## 🧪 Testing

### Test FTP Connection

```bash
# Basic FTP test
ftp ftp.example.com

# FTPS test (if enabled)
ftp-ssl ftp.example.com
```

### Test SFTP Connection

```bash
sftp ftpuser1@ftp.example.com

# Or with specific port
sftp -P 22 ftpuser1@ftp.example.com
```

## 🛠 Troubleshooting

### Users can't log in

1. Check user exists: `id username`
2. Check password hash in `/etc/shadow`
3. Check logs: `journalctl -u vsftpd` or `journalctl -u sshd`
4. Verify user is in correct group: `groups username`

### Passive mode not working

1. Verify `vsftpd_pasv_address` is set to your external IP or domain
2. Check passive ports are open in firewall
3. Verify port range is correct: `ss -tln | grep -E ':(21|10[0-9]{3})'`

### FTPS certificate errors

1. Verify certificate files exist and are readable
2. Check certificate paths in `/etc/vsftpd/vsftpd.conf`
3. Test with: `openssl s_client -connect ftp.example.com:21 -starttls ftp`

### Chroot issues

1. Ensure home directory root is owned by root: `ls -ld /data/username`
2. Verify subdirectories exist and are owned by user: `ls -la /data/username/`
3. Check SELinux if enabled: `getsebool -a | grep ftp`

## 📁 Directory Structure

```
ansible/
├── site.yml                          # Main playbook
├── inventory.yml.example             # Example inventory
├── README.md                         # This file
└── roles/
    ├── vsftpd/                       # VSFTPD role
    │   ├── defaults/main.yml         # Default variables
    │   ├── handlers/main.yml         # Service handlers
    │   ├── tasks/main.yml            # Installation & config tasks
    │   └── templates/
    │       ├── vsftpd.conf.j2        # VSFTPD config template
    │       ├── user_list.j2          # User restrictions
    │       └── ftpusers.j2           # Denied users
    ├── sshd_sftp/                    # SSH/SFTP role
    │   ├── defaults/main.yml         # Default variables
    │   ├── handlers/main.yml         # Service handlers
    │   ├── tasks/main.yml            # Configuration tasks
    │   └── templates/
    │       └── 10-sftp_config.conf.j2  # SFTP config template
    └── user_management/              # User management role
        ├── defaults/main.yml         # Default variables
        ├── tasks/main.yml            # User sync tasks
        └── templates/
            └── update_users.sh.j2    # User sync script
```

## 🔗 Related

This playbook replicates the configuration from the Docker container project:
- **Container Repository:** [DogsbodyServices/vsftpd_container](https://github.com/DogsbodyServices/vsftpd_container)
- **Container README:** See main repository for container-specific documentation

## 🧾 License

This playbook inherits the license from the parent vsftpd_container project.

See [COPYING](../COPYING) for details (GPLv3).

## 🤝 Contributing

When contributing improvements:
1. Ensure changes maintain compatibility with the container configuration
2. Test on supported operating systems
3. Update this README with any new variables or features
4. Follow Ansible best practices

## 📞 Support

For issues specific to:
- **This playbook:** Open an issue in the main repository
- **Container version:** See container documentation
- **VSFTPD itself:** Check [VSFTPD documentation](https://security.appspot.com/vsftpd.html)
- **OpenSSH SFTP:** Check [OpenSSH documentation](https://www.openssh.com/)
