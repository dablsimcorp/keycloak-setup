# Keycloak Setup - Quick Deployment Guide

## 🚀 Deploy from GitHub Repository

This guide shows how to deploy Keycloak on any machine using the GitHub repository.

---

## Quick Start (3 Commands)

```bash
# 1. Clone the repository
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# 2. Copy and configure environment
cp .env.example .env
vim .env  # Edit KC_HOSTNAME and passwords

# 3. Deploy (automated)
./deploy.sh
```

**Access**: http://localhost:8080/admin (or your configured hostname)
**Credentials**: admin / admin (change immediately!)

---

## Detailed Deployment Steps

### Step 1: Clone the Repository

```bash
# Clone to your local machine or server
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
```

### Step 2: Install Prerequisites (if needed)

```bash
# The script detects your OS and installs dependencies
./install-prerequisites.sh
```

This installs:
- Podman (container runtime)
- podman-compose (orchestration)
- curl, openssl, net-tools

**Supported OS**: Ubuntu, Debian, RHEL, Rocky Linux, Fedora

### Step 3: Configure Environment

```bash
# Create your environment file
cp .env.example .env

# Edit with your settings
nano .env  # or vim, or any editor
```

**Important settings to update**:
```bash
KC_HOSTNAME=your-server-ip-or-domain  # e.g., 192.168.1.100 or keycloak.example.com
KEYCLOAK_ADMIN_PASSWORD=your-secure-password
POSTGRES_PASSWORD=your-database-password
```

### Step 4: Deploy Keycloak

**Option A - Automated Deployment (Recommended)**:
```bash
./deploy.sh
```

**Option B - Step-by-Step**:
```bash
./configure-network.sh  # Interactive network configuration
./start.sh              # Start services
./status.sh             # Check status
```

### Step 5: Configure Firewall (if accessing from network)

```bash
# Ubuntu/Debian
sudo ufw allow 8080/tcp

# RHEL/CentOS/Fedora
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### Step 6: Access Keycloak

- **Local**: http://localhost:8080/admin
- **Network**: http://YOUR_IP:8080/admin
- **Domain**: http://keycloak.yourdomain.com:8080/admin

**Login** with credentials from your `.env` file (default: admin/admin)

---

## Deployment Scenarios

### Scenario 1: Local Development

```bash
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
cp .env.example .env
# Keep KC_HOSTNAME=localhost
./start.sh
```

### Scenario 2: Network Server (LAN)

```bash
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
cp .env.example .env
./configure-network.sh  # Select option 2 (Network access)
sudo ufw allow 8080/tcp
```

### Scenario 3: Cloud VM (Production)

```bash
# SSH into your cloud VM
ssh user@cloud-vm-ip

# Clone and deploy
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
cp .env.example .env

# Edit .env with your domain and strong passwords
vim .env

# Deploy with HTTPS
./generate-ssl.sh  # Or use Let's Encrypt
podman-compose up -d
```

### Scenario 4: Multiple Environments

```bash
# Development Environment
git clone https://github.com/dablsimcorp/keycloak-setup.git keycloak-dev
cd keycloak-dev
cp .env.example .env
# Set KC_HOSTNAME=dev.example.com
./deploy.sh

# Production Environment
git clone https://github.com/dablsimcorp/keycloak-setup.git keycloak-prod
cd keycloak-prod
cp .env.example .env
# Set KC_HOSTNAME=keycloak.example.com with strong passwords
./deploy.sh
```

---

## Using with Different Container Runtimes

### Podman (Default)

```bash
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./deploy.sh
```

### Docker

Not supported. Use Podman or WSL2 on Windows.

---

## Management Commands

```bash
# Start services
./start.sh

# Stop services
./stop.sh

# Check status
./status.sh

# View logs
podman logs -f keycloak

# Restart with new configuration
podman restart keycloak

# Full cleanup and restart
./stop.sh
podman rm keycloak keycloak-postgres
./start.sh
```

---

## Configuration Files

```
keycloak-setup/
├── .env.example              # Configuration template
├── docker-compose.yml        # Main compose file (development)
├── docker-compose.prod.yml   # Production configuration
├── docker-compose.nginx.yml  # With nginx reverse proxy
├── start.sh                  # Start services
├── stop.sh                   # Stop services
├── status.sh                 # Check health
├── deploy.sh                 # Automated deployment
├── configure-network.sh      # Network configuration wizard
├── generate-ssl.sh           # SSL certificate generator
├── install-prerequisites.sh  # Install dependencies
├── package-for-deployment.sh # Create deployment package
├── README.md                 # Main documentation
├── QUICKSTART.md             # Quick start guide
├── NETWORK-SETUP.md          # Network configuration guide
├── DEPLOYMENT.md             # Detailed deployment scenarios
└── nginx/
    └── nginx.conf            # Nginx configuration
```

---

## Update Existing Deployment

To update an existing deployment with latest changes:

```bash
cd keycloak-setup

# Save your .env file
cp .env .env.backup

# Pull latest changes
git pull origin main

# Restore your configuration
cp .env.backup .env

# Restart services
./stop.sh
./start.sh
```

---

## Automated Deployment Examples

### Deploy via SSH

```bash
# From your local machine
ssh user@remote-server "git clone https://github.com/dablsimcorp/keycloak-setup.git && cd keycloak-setup && ./install-prerequisites.sh"

# Configure environment (edit .env on remote)
ssh user@remote-server "cd keycloak-setup && cp .env.example .env"

# Start services
ssh user@remote-server "cd keycloak-setup && ./deploy.sh"
```

### Ansible Playbook

```yaml
---
- name: Deploy Keycloak
  hosts: keycloak_servers
  become: yes
  tasks:
    - name: Clone repository
      git:
        repo: https://github.com/dablsimcorp/keycloak-setup.git
        dest: /opt/keycloak-setup
        
    - name: Install prerequisites
      command: /opt/keycloak-setup/install-prerequisites.sh
      
    - name: Configure environment
      template:
        src: env.j2
        dest: /opt/keycloak-setup/.env
        
    - name: Deploy Keycloak
      command: /opt/keycloak-setup/deploy.sh
```

---

## Troubleshooting

### Issue: Git clone fails

```bash
# Check internet connectivity
ping github.com

# Use HTTPS if SSH fails
git clone https://github.com/dablsimcorp/keycloak-setup.git
```

### Issue: Permission denied

```bash
# Make scripts executable
chmod +x *.sh

# Or use sudo for system operations
sudo ./install-prerequisites.sh
```

### Issue: Can't access Keycloak

```bash
# Check if running
podman ps

# Check logs
podman logs keycloak

# Verify configuration
cat .env | grep KC_HOSTNAME

# Check firewall
sudo ufw status
```

---

## Security Checklist

Before going to production:

- [ ] Clone the repository to your server
- [ ] Create `.env` from `.env.example`
- [ ] Change `KEYCLOAK_ADMIN_PASSWORD` to a strong password
- [ ] Change `POSTGRES_PASSWORD` to a strong password
- [ ] Set `KC_HOSTNAME` to your actual domain
- [ ] Enable HTTPS with `./generate-ssl.sh` or Let's Encrypt
- [ ] Configure firewall properly
- [ ] Regular backups of PostgreSQL data
- [ ] Keep Keycloak updated: `git pull && restart`

---

## Repository Structure

**GitHub**: https://github.com/dablsimcorp/keycloak-setup

**Clone URL**: 
```
https://github.com/dablsimcorp/keycloak-setup.git
```

**SSH URL**: 
```
git@github.com:dablsimcorp/keycloak-setup.git
```

---

## Support & Resources

- **Repository**: https://github.com/dablsimcorp/keycloak-setup
- **Issues**: https://github.com/dablsimcorp/keycloak-setup/issues
- **Documentation**: See README.md, QUICKSTART.md, NETWORK-SETUP.md, DEPLOYMENT.md
- **Keycloak Docs**: https://www.keycloak.org/documentation

---

## Contributing

Pull requests are welcome! For major changes:

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## License

This project is provided as-is for educational and production use.

---

## Quick Reference Card

```bash
# CLONE
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# CONFIGURE
cp .env.example .env
vim .env  # Update KC_HOSTNAME, passwords

# DEPLOY
./deploy.sh  # Automated
# OR
./configure-network.sh && ./start.sh  # Step-by-step

# MANAGE
./status.sh  # Check health
./stop.sh    # Stop
./start.sh   # Start
podman logs -f keycloak  # View logs

# ACCESS
http://YOUR_IP:8080/admin
Username: admin
Password: (from .env)
```

**Happy Deploying! 🚀**
