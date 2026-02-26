# Quick Start Guide - Keycloak with Podman

This guide provides step-by-step instructions to run Keycloak locally with HTTPS support.

## Prerequisites

You need **Podman** 3.0+ installed:
```bash
podman --version  # Should show 3.0 or higher
```

## Installation

First, install podman-compose if you don't have it:
```bash
# On most Linux systems
sudo curl -o /usr/local/bin/podman-compose https://raw.githubusercontent.com/containers/podman-compose/main/podman-compose
sudo chmod +x /usr/local/bin/podman-compose
```

---

## Quick Start: HTTPS Default

### Step 1: Generate SSL Certificate
```bash
cd /home/sa/repo/idp-setup
./generate-ssl.sh
# When prompted, press 'y' and enter your machine's IP or hostname
```

### Step 2: Start Keycloak with HTTPS
```bash
podman-compose up -d
```

### Step 3: Verify Services Are Running
```bash
podman-compose ps
```

### Step 4: Access Keycloak via HTTPS
- **URL**: https://localhost
- **Admin Console**: https://localhost/admin
- **Username**: `admin`
- **Password**: `admin`

**Note**: Your browser will show a certificate warning (self-signed cert). Click "Proceed Anyway" or "Advanced" to continue.

### Step 5: View Logs
```bash
podman-compose logs -f
```

### Step 6: Stop Services
```bash
podman-compose down
```

---

## Helper Scripts

We've provided shell scripts for quick management:

### Start Keycloak with Default HTTPS
```bash
./start.sh  # Note: for local HTTP-only, see alternatives
```

### Check Status
```bash
./status.sh
```

### Stop Keycloak
```bash
./stop.sh
```

### Configure Network (for external access)
```bash
./configure-network.sh
```

### Generate SSL Certificates
```bash
./generate-ssl.sh
```


---

## Common Tasks

### Access Keycloak Admin Console
1. For HTTPS: Navigate to https://localhost/admin
2. For HTTP: Navigate to http://localhost:8080/admin
3. Login with:
   - Username: `admin`
   - Password: `admin`

### Add a New Realm
1. Click "Master" dropdown (top-left)
2. Click "Create Realm"
3. Enter realm name (e.g., "my-app")
4. Click "Create"

### Create an OIDC Client
1. Go to Clients → Create client
2. Name: `my-app-client`
3. Protocol: `openid-connect`
4. Client Type: `Web application`
5. Configure Redirect URIs: `https://localhost:3000/*` or `http://localhost:3000/*`
6. Save and get credentials from "Credentials" tab

### Create a Test User
1. Go to Users → Create new user
2. Username: `testuser`
3. Email: `test@example.com`
4. Toggle "Email verified" ON
5. Go to Credentials tab → Set password: `test123`

---

## Troubleshooting

### Services Don't Start
```bash
# Check Podman logs
journalctl -u podman -f

# Try starting with verbose output
podman-compose up
```

### Port Already in Use
```bash
# For HTTPS setup (ports 80/443):
sudo lsof -i :80
sudo lsof -i :443

# For HTTP setup (port 8080):
lsof -i :8080
```

### PostgreSQL Connection Issues
```bash
# Check PostgreSQL logs
podman-compose logs postgres

# Connect to PostgreSQL directly
psql -h localhost -U keycloak -d keycloak
# Password: keycloak
```

### Reset Everything
```bash
# Remove all containers and data
podman-compose down -v

# Then restart fresh
podman-compose up -d
```

---

## Health Checks

Verify services are healthy:

```bash
# Check HTTPS endpoint
curl -k https://localhost/health/ready
# Expected output: {"status":"UP"}

# PostgreSQL connectivity
nc -zv localhost 5432
# Expected output: Connection succeeded
```

---

## Next Steps

After Keycloak is running:

1. ✅ Access the Admin Console (https:// or http://)
2. 📝 Create a new realm for your application
3. 👥 Create test users
4. 🔑 Create OIDC clients for your apps
5. 🔗 Integrate your application using OIDC endpoints

---

## Integration Examples

### Get OpenID Configuration
```bash
curl -k https://localhost/realms/my-realm/.well-known/openid-configuration
```

### Get Access Token Example
```bash
curl -X POST https://localhost/realms/my-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=my-client" \
  -d "client_secret=your-secret" \
  -d "username=testuser" \
  -d "password=test123" \
  -d "grant_type=password"
```

### Node.js Integration
```javascript
const OpenID = require('openid-client');

const config = await OpenID.discovery('https://localhost/realms/my-realm');
const client = new OpenID.Client({
  client_id: 'my-client-id',
  client_secret: 'my-client-secret',
  redirect_uris: ['http://localhost:3000/callback']
});
```

---

## Security Notes

❌ **Development Only**: Current settings are for local development.

For production:
- [ ] Change admin password
- [ ] Use strong database password
- [ ] Enable HTTPS/TLS
- [ ] Use environment variables for secrets
- [ ] Implement backup strategy
- [ ] Configure proper hostname
- [ ] Use reverse proxy (nginx/traefik)

---

## Useful Commands

```bash
# View all containers
docker-compose ps
podman-compose ps

# View logs for specific service
docker-compose logs keycloak
podman-compose logs keycloak

# Execute command in container
docker-compose exec keycloak bash
podman-compose exec keycloak bash

# Remove all data and containers
docker-compose down -v
podman-compose down -v

# View resource usage
docker stats
podman stats

# Rebuild images
docker-compose build
podman-compose build
```

---

## Support & Documentation

- Keycloak Admin Guide: https://www.keycloak.org/docs/latest/server_admin/
- OpenID Connect: https://openid.net/connect/
- OAuth 2.0: https://oauth.net/2/
- Docker Compose: https://docs.docker.com/compose/
- Podman: https://podman.io/
