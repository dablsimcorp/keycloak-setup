# Deployment Guide

Deploy Keycloak to other machines or servers.

## Overview

This guide covers deploying Keycloak to:
- Cloud servers (AWS, Azure, Google Cloud, etc.)
- On-premises servers
- Remote machines
- Multiple environments (dev, staging, production)

## Quick Deployment (3 Steps)

```bash
# 1. Copy setup to target machine
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# 2. Install dependencies
./install-prerequisites.sh

# 3. Deploy
./deploy.sh
```

That's it! Services run at your machine's IP with HTTPS.

## Detailed Deployment Methods

### Method 1: From GitHub (Recommended)

Simple deployment when target machine has git and internet.

**On target machine:**

```bash
# 1. Clone repository
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# 2. Install dependencies
sudo chmod +x *.sh
./install-prerequisites.sh

# 3. Configure (optional)
cp .env.example .env
nano .env  # Update KC_HOSTNAME, passwords, etc.

# 4. Deploy
./deploy.sh
```

**Access via:**
- Local: `https://localhost/admin`
- Network: `https://YOUR_IP/admin`

### Method 2: From Another Machine (scp)

Transfer setup files via SSH.

**From source machine:**

```bash
# Copy entire setup directory
scp -r /path/to/keycloak-setup user@target-machine:/tmp/

# Or compress first
tar -czf keycloak-setup.tar.gz keycloak-setup/
scp keycloak-setup.tar.gz user@target-machine:~/
```

**On target machine:**

```bash
# Extract
tar -xzf keycloak-setup.tar.gz
cd keycloak-setup

# Install and deploy
./install-prerequisites.sh
./deploy.sh
```

### Method 3: Containerized Deployment

Export and import containers between machines.

**On source machine:**

```bash
# Export container images
podman save -o keycloak-image.tar quay.io/keycloak/keycloak:latest
podman save -o postgres-image.tar docker.io/library/postgres:16-alpine

# Create deployment package
tar -czf keycloak-deployment.tar.gz \
  keycloak-image.tar \
  postgres-image.tar \
  docker-compose.yml \
  .env.example \
  nginx/ \
  *.sh
```

**On target machine:**

```bash
# Extract package
tar -xzf keycloak-deployment.tar.gz

# Load container images
podman load -i keycloak-image.tar
podman load -i postgres-image.tar

# Configure
cp .env.example .env
nano .env  # Edit configuration

# Install podman-compose if needed
sudo curl -o /usr/local/bin/podman-compose \
  https://raw.githubusercontent.com/containers/podman-compose/main/podman-compose
sudo chmod +x /usr/local/bin/podman-compose

# Deploy
podman-compose up -d
```

## Cloud Deployment

### AWS EC2

```bash
# 1. Launch Ubuntu 22.04 instance
# 2. Connect via SSH

# 3. Clone and deploy
sudo apt update
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./install-prerequisites.sh

# 4. Configure for your domain
nano .env
# Set: KC_HOSTNAME=your-domain.com
# Update passwords!

# 5. Deploy
sudo ./deploy.sh

# 6. Configure Security Group
# Allow inbound: TCP 80, 443 from 0.0.0.0/0
```

Access: `https://your-domain.com/admin`

### DigitalOcean Droplet

```bash
# 1. Create Ubuntu 22.04 droplet
# 2. SSH into droplet

# 3. Deploy (same as AWS)
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./install-prerequisites.sh
nano .env  # Configure

# 4. Update firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 5. Start
podman-compose up -d
```

### Google Cloud Platform

```bash
# 1. Create Compute Engine instance (Ubuntu 22.04)
# 2. SSH via console or local connection

# 3. Deploy
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./install-prerequisites.sh

# 4. Configure .env
nano .env
# KC_HOSTNAME=your-gcp-instance-ip

# 5. Create firewall rules in GCP Console
# Allow: TCP 80, 443 from 0.0.0.0/0

# 6. Start services
podman-compose up -d
```

### Azure

```bash
# 1. Create VM (Ubuntu 22.04)
# 2. SSH into VM

# 3. Deploy
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./install-prerequisites.sh

# 4. Configure
nano .env

# 5. Configure Network Security Group
# Add inbound rules: TCP 80, 443

# 6. Start
podman-compose up -d
```

## Multiple Environments

### Development

Default configuration works for development:

```bash
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./deploy.sh
```

Default credentials (change immediately):
- Admin: `admin` / `admin`
- Database: `keycloak` / `keycloak`

### Staging

For staging environment:

```bash
# Clone with specific branch (if available)
git clone -b staging https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# Configure for staging domain
cp .env.example .env
nano .env
# KC_HOSTNAME=staging-keycloak.example.com
# Generate real SSL certificate (Let's Encrypt)

./deploy.sh
```

### Production

For production deployments:

```bash
# Clone
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# Configure with production settings
cp .env.example .env
nano .env
```

Edit `.env` for production:
```bash
# Use real domain
KC_HOSTNAME=keycloak.example.com

# Use strong passwords (generate with: openssl rand -base64 32)
KEYCLOAK_ADMIN_PASSWORD=<generate-strong-password>
POSTGRES_PASSWORD=<generate-strong-password>

# Production containers (not dev-mode)
# Consider building custom image without dev mode
```

Configure HTTPS with real certificate:

```bash
# Get Let's Encrypt certificate
sudo certbot certonly --standalone -d keycloak.example.com

# Copy to nginx/ssl/
sudo cp /etc/letsencrypt/live/keycloak.example.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/keycloak.example.com/privkey.pem nginx/ssl/key.pem

# Set permissions
sudo chown $(whoami): nginx/ssl/*

# Deploy
podman-compose up -d
```

### Environment Variables

Store sensitive data in `.env` (never commit to git):

```bash
# .env.example (committed to git)
KC_HOSTNAME=localhost
KEYCLOAK_ADMIN_PASSWORD=admin
POSTGRES_PASSWORD=postgres

# .env (local, not committed - auto-generated)
# DO NOT COMMIT THIS FILE
```

For each environment:

```bash
# Production server
cp .env.example .env
# Edit with production values
# Never commit .env!
```

## Post-Deployment

### 1. Verify Services

```bash
# Check containers
podman-compose ps

# Check health
curl -k https://localhost/health/ready

# View logs
podman-compose logs -f keycloak
```

### 2. Access Admin Console

Navigate to:
```
https://YOUR_IP/admin
```

Login with credentials from `.env`.

### 3. Change Default Password

1. Login to Keycloak admin console
2. Click on user icon → Account
3. Click Password tab
4. Enter new password
5. Click Save

### 4. Configure Backup

PostgreSQL database backup:

```bash
# Backup script (save as backup.sh)
#!/bin/bash
BACKUP_DIR="/path/to/backups"
podman exec keycloak-postgres pg_dump -U keycloak -d keycloak > $BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).sql
```

Schedule daily with cron:

```bash
crontab -e
# Add: 0 2 * * * /path/to/backup.sh
```

### 5. Set Up Monitoring

Monitor logs and services:

```bash
# Watch logs in real-time
podman-compose logs -f

# Setup alerts (example with systemd)
# Create systemd service to restart if stopped
```

### 6. Configure Domain

If using custom domain:

1. Add DNS A record pointing to your server IP
2. Update `.env`: `KC_HOSTNAME=your-domain.com`
3. Get SSL certificate (Let's Encrypt)
4. Restart: `podman-compose restart`

## Troubleshooting Deployment

### Connection Refused

```bash
# Check if services are running
podman-compose ps

# Check logs
podman-compose logs keycloak

# Verify ports
sudo netstat -tulpn | grep -E "(80|443)"
```

### SSL Certificate Errors

```bash
# Verify certificate exists
ls -la nginx/ssl/

# Check certificate validity
openssl x509 -in nginx/ssl/cert.pem -text -noout
```

### Database Connection Issues

```bash
# Check postgres
podman-compose logs postgres

# Test connection
podman exec keycloak-postgres psql -U keycloak -c "SELECT 1"
```

### Performance Issues

```bash
# Monitor resource usage
podman stats

# Check memory
podman-compose logs keycloak | grep -i memory

# Increase resources in docker-compose.yml if needed
```

## Maintenance

### Regular Tasks

- **Weekly**: Check logs for errors
- **Monthly**: Review backups
- **Quarterly**: Update certificates if needed
- **Annually**: Plan upgrades to new Keycloak version

### Update Keycloak

```bash
# Pull latest images
podman pull quay.io/keycloak/keycloak:latest
podman pull docker.io/library/postgres:16-alpine

# Restart services
podman-compose down
podman-compose up -d
```

### Backup Before Updates

```bash
# Backup database
podman exec keycloak-postgres pg_dump -U keycloak -d keycloak > backup-before-update.sql

# Update
podman-compose pull
podman-compose up -d
```

## Support

- **Official Docs**: https://www.keycloak.org/documentation
- **Docker Hub**: https://hub.docker.com/r/keycloak/keycloak
- **GitHub**: https://github.com/keycloak/keycloak

## Next Steps

1. **Deploy to your target environment**
2. **Configure your domain and SSL**
3. **Create realms and clients**
4. **Integrate applications**
5. **Setup monitoring and backups**

---

**Quick Reference**

| Task | Command |
|------|---------|
| Deploy | `./deploy.sh` |
| Start | `podman-compose up -d` |
| Stop | `podman-compose down` |
| Logs | `podman-compose logs -f` |
| Status | `./status.sh` |
| Restart | `podman-compose restart` |
| Update | `podman-compose pull && podman-compose up -d` |

---

For more help, see [README.md](README.md) or [QUICKSTART.md](QUICKSTART.md).

### On Source Machine (this machine):

```bash
# Save container images
podman save -o keycloak.tar quay.io/keycloak/keycloak:latest
podman save -o postgres.tar docker.io/library/postgres:16-alpine

# Create deployment package
tar -czf keycloak-deployment.tar.gz \
  keycloak.tar \
  postgres.tar \
  docker-compose.yml \
  .env \
  *.sh \
  nginx/
```

### On Target Machine:

```bash
# Extract deployment package
tar -xzf keycloak-deployment.tar.gz

# Load container images
podman load -i keycloak.tar
podman load -i postgres.tar

# Install podman-compose if needed
sudo apt install podman-compose  # Ubuntu/Debian
# Or
sudo dnf install podman-compose  # RHEL/Fedora

# Configure and start
./configure-network.sh
./start.sh
```

---

## Method 3: Fresh Installation on External Machine

If you want to reproduce the setup from scratch:

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y podman podman-compose curl

# RHEL/CentOS/Fedora
sudo dnf install -y podman podman-compose curl

# Verify installation
podman --version
podman-compose --version
```

### Automated Setup

Copy the setup files to the target machine, then:

```bash
cd idp-setup

# Run automated installation
./install-prerequisites.sh  # Installs dependencies
./configure-network.sh      # Configure network settings
./start.sh                  # Start services

# Wait 30-60 seconds for Keycloak to initialize
# Then access: https://<target-machine-ip>/admin
```

---

## Method 4: Cloud Deployment (AWS, Azure, GCP, DigitalOcean)

### Prerequisites on Cloud VM:

1. **Provision a VM:**
   - Minimum: 2 vCPU, 4GB RAM
   - Recommended: 2 vCPU, 8GB RAM
   - OS: Ubuntu 22.04/24.04 or RHEL 9

2. **Open firewall/security group:**
   - Port 8080 (HTTP)
   - Port 443 (HTTPS, if using SSL)
   - SSH Port 22 (for management)

3. **Connect and install:**

```bash
# SSH into the VM
ssh user@cloud-vm-ip

# Install Podman
sudo apt update && sudo apt install -y podman podman-compose

# Transfer and extract setup
# (use scp or git clone)

# Configure
cd idp-setup
./configure-network.sh  # Use public IP or domain name
./start.sh
```

4. **For production with HTTPS:**

```bash
# Generate SSL certificate (Let's Encrypt)
./generate-ssl.sh

# Update nginx config for HTTPS
# Start with nginx
podman-compose up -d
```

---

## Environment Configuration

Each external machine should have its own `.env` configuration:

### Development/Testing Machine:
```bash
KC_HOSTNAME=192.168.1.100  # Local network IP
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
```

### Staging Server:
```bash
KC_HOSTNAME=staging.example.com
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=StrongPassword123!
POSTGRES_PASSWORD=SecureDBPassword456!
```

### Production Server:
```bash
KC_HOSTNAME=keycloak.example.com
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=<use-strong-password>
POSTGRES_PASSWORD=<use-strong-password>
KC_PROXY=edge
NGINX_HTTPS_PORT=443
```

---

## Deployment Checklist

Before deploying to external machines:

### Pre-Deployment
- [ ] Backup current `.env` file
- [ ] Update `.env` with target machine credentials
- [ ] Change default passwords
- [ ] Update `KC_HOSTNAME` to target machine's IP/domain
- [ ] Ensure required ports are open in firewall

### Deployment
- [ ] Install Podman/Docker on target machine
- [ ] Transfer project files
- [ ] Run `./configure-network.sh`
- [ ] Start services with `./start.sh`
- [ ] Verify services are running: `podman ps`

### Post-Deployment
- [ ] Access admin console and login
- [ ] Change admin password immediately
- [ ] Create realms and clients
- [ ] Configure backup strategy
- [ ] Set up monitoring/logging
- [ ] Enable HTTPS for production
- [ ] Document access URLs and credentials

---

## Multi-Machine Architecture

### Scenario: Multiple Environments

```
┌─────────────────────────────────────────────────┐
│  Development (192.168.1.100:8080)               │
│  - Local development                            │
│  - HTTP only                                    │
│  - Default credentials OK                       │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Staging (staging.example.com)                  │
│  - Testing environment                          │
│  - HTTPS with self-signed cert                 │
│  - Strong passwords                             │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Production (keycloak.example.com)              │
│  - Public-facing                                │
│  - HTTPS with Let's Encrypt                    │
│  - Database backups                             │
│  - Monitoring enabled                           │
│  - High availability setup                      │
└─────────────────────────────────────────────────┘
```

---

## Remote Management

### Managing Services on External Machines

```bash
# SSH into remote machine
ssh user@external-machine

cd /path/to/idp-setup

# Check status
./status.sh
podman ps

# View logs
podman logs -f keycloak
podman logs -f keycloak-postgres

# Restart services
podman restart keycloak
# Or full restart
./stop.sh && ./start.sh

# Update configuration
vim .env  # Edit settings
podman restart keycloak  # Apply changes

# Backup data
podman exec keycloak-postgres pg_dump -U keycloak keycloak > backup.sql
```

---

## Docker Compose Deployment (Alternative to Podman)

If the target machine uses Docker instead of Podman:

```bash
# On target machine with Docker
sudo apt install docker.io docker-compose

# Copy project files
scp -r idp-setup user@target:/home/user/

# Start with Docker Compose
cd idp-setup
sudo docker-compose up -d

# Check status
sudo docker-compose ps
sudo docker-compose logs -f keycloak
```

---

## Kubernetes Deployment (Advanced)

For large-scale deployments, consider Kubernetes:

```yaml
# keycloak-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
spec:
  replicas: 2
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:latest
        env:
        - name: KC_HOSTNAME
          value: "keycloak.example.com"
        - name: KEYCLOAK_ADMIN
          value: "admin"
        - name: KEYCLOAK_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: keycloak-secret
              key: password
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 8080
  selector:
    app: keycloak
```

Deploy with:
```bash
kubectl apply -f keycloak-deployment.yaml
```

---

## Synchronizing Multiple Instances

If you need to keep multiple Keycloak instances in sync:

### Option 1: Shared Database
- All Keycloak instances connect to the same PostgreSQL database
- Ensures data consistency across instances

### Option 2: Realm Export/Import
```bash
# Export realm from source
podman exec keycloak /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm my-realm

# Copy to target machine
podman cp keycloak:/tmp/export/my-realm.json realm-export.json
scp realm-export.json user@target-machine:~

# Import on target
scp realm-export.json user@target-machine:~
ssh user@target-machine
podman cp realm-export.json keycloak:/tmp/
podman exec keycloak /opt/keycloak/bin/kc.sh import --file /tmp/realm-export.json
```

---

## Troubleshooting External Deployments

### Issue: Can't access Keycloak from external machine

1. **Check if Keycloak is running:**
```bash
podman ps | grep keycloak
```

2. **Check hostname configuration:**
```bash
grep KC_HOSTNAME .env
```

3. **Check firewall:**
```bash
sudo ufw status
sudo ufw allow 8080/tcp
```

4. **Check network connectivity:**
```bash
# From external machine
telnet target-machine-ip 8080
curl -k https://target-machine-ip/
```

### Issue: Database connection errors

```bash
# Check PostgreSQL is running
podman ps | grep postgres

# Check database logs
podman logs keycloak-postgres

# Verify database connectivity
podman exec keycloak-postgres psql -U keycloak -d keycloak -c "SELECT 1;"
```

---

## Security Considerations for External Deployments

1. **Always change default passwords**
2. **Use HTTPS in production** (Let's Encrypt)
3. **Restrict admin console access** (firewall rules)
4. **Regular security updates**
5. **Enable database backups**
6. **Use secrets management** (Vault, AWS Secrets Manager)
7. **Monitor access logs**
8. **Implement rate limiting**
9. **Regular security audits**
10. **Use non-root containers** (already configured)

---

## Support & Resources

- Project repository: Your Git repository
- Keycloak documentation: https://www.keycloak.org/documentation
- Container docs: https://podman.io/ or https://docs.docker.com/
- Let's Encrypt: https://letsencrypt.org/

For issues specific to deployment, check:
1. Container logs: `podman logs keycloak`
2. Status script: `./status.sh`
3. [NETWORK-SETUP.md](NETWORK-SETUP.md) for network configuration
4. [QUICKSTART.md](QUICKSTART.md) for setup steps
