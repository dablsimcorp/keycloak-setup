# Deploying Keycloak to External Machines

This guide explains how to deploy this Keycloak setup to other servers or machines.

## Quick Start for External Machines

### Method 1: Clone/Copy the Setup (Recommended)

1. **Transfer the project to the target machine:**

```bash
# Option A: If you have Git repository
git clone <your-repo-url>
cd idp-setup

# Option B: Using scp to copy from this machine
scp -r /home/sa/repo/idp-setup user@target-machine:/path/to/destination/

# Option C: Create a tarball and transfer
tar -czf idp-setup.tar.gz /home/sa/repo/idp-setup
scp idp-setup.tar.gz user@target-machine:~
# Then on target machine:
tar -xzf idp-setup.tar.gz
```

2. **On the target machine, install prerequisites:**

```bash
cd idp-setup
./install-prerequisites.sh
```

3. **Configure for the target machine's network:**

```bash
./configure-network.sh
```

4. **Start Keycloak:**

```bash
./start.sh
```

---

## Method 2: Container Image Export/Import

Export the containers from this machine and import on the target:

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
