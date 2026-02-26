# Keycloak Identity Provider - Local Setup

This project sets up **Keycloak**, an open-source identity and access management solution, locally using Podman/Docker.

## 🚀 Quick Deploy from GitHub

```bash
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
cp .env.example .env  # Configure settings
./deploy.sh           # Automated deployment
```

See [GITHUB-DEPLOY.md](GITHUB-DEPLOY.md) for complete deployment instructions from this repository.

## Overview

Keycloak is a powerful, certified OpenID Connect (OIDC) and OAuth 2.0 provider that can be used as a standalone authentication server or integrated with other applications.

**Key Features:**
- OpenID Connect and OAuth 2.0 support
- User federation and social login
- Strong authentication (2FA, WebAuthn)
- User and role management
- Realm separation for multi-tenancy
- REST Admin API
- Extensible through plugins and themes

## Prerequisites

### Option 1: Using Podman (Preferred)
```bash
podman --version  # Should be 3.0+
```

### Windows Users (WSL2 Only)

This setup supports Windows only via WSL2. See [WINDOWS.md](WINDOWS.md).

## Quick Start

### 1. Start Keycloak with HTTPS (Recommended)

For secure HTTPS access with nginx reverse proxy (default):

```bash
cd /home/sa/repo/idp-setup

# Generate SSL certificate (do this once)
./generate-ssl.sh

# Start with HTTPS enabled
podman-compose up -d
```

### 2. Access Keycloak via HTTPS

- **URL**: https://localhost
- **Admin Console**: https://localhost/admin  
- **Username**: `admin`
- **Password**: `admin`

**Note**: Self-signed certificate will show browser warning (expected). Click "Proceed Anyway" or "Advanced" to continue.

### 3. For Network Access (Other Machines)

To access Keycloak from another machine on your network:

```bash
# Configure your machine's IP or hostname
./configure-network.sh

# Regenerate SSL certificate for your IP/hostname
./generate-ssl.sh

# Restart with HTTPS
podman-compose down
podman-compose up -d
```

Then access from other machines using: `https://your-machine-ip`

See [NETWORK-SETUP.md](NETWORK-SETUP.md) for detailed network configuration instructions.

### 4. Verify Services

```bash
# Check running containers
podman-compose ps

# View logs
podman-compose logs -f
```

### 5. Stop Keycloak

```bash
podman-compose down
```

## Create a Realm and Client

1. Log in to the Admin Console
2. Click "Create Realm" → Name it (e.g., `my-realm`)
3. Navigate to Clients → Create Client
4. Configure redirect URIs for your application
5. Get the Client ID and Secret from the Credentials tab

## Configuration

### Environment Variables

Edit `.env` to customize:

```bash
# Keycloak Admin
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin

# PostgreSQL
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=keycloak

# Hostname
KC_HOSTNAME=localhost
```

### Database Options

**Current Setup**: PostgreSQL 16 (production-ready)

**Alternative - Embedded H2** (development only):
```yaml
# In docker-compose.yml, modify keycloak service:
command: 
  - "start-dev"
  # H2 is built-in for start-dev
```

## Managing Services

### Start Services
```bash
./start.sh
# Or: podman-compose up -d
```

### Configure Network Access
```bash
./configure-network.sh
```

### Generate SSL Certificates
```bash
./generate-ssl.sh
```

### Stop Services
```bash
./stop.sh
# Or: podman-compose down
```

### Stop and Remove Data
```bash
podman-compose down -v  # -v removes volumes
```

### View Logs
```bash
podman-compose logs -f keycloak
podman-compose logs -f postgres
```

### Shell Access
```bash
# Access Keycloak container
podman exec -it keycloak /bin/bash

# Access PostgreSQL
podman exec -it keycloak-postgres psql -U keycloak -d keycloak
```

## Integration with Applications

### OpenID Connect Discovery
```
http://localhost:8080/realms/my-realm/.well-known/openid-configuration
```

### Common Integration Patterns

**Node.js/Express with OpenID Client:**
```javascript
const OpenID = require('openid-client');

const config = await OpenID.discovery('http://localhost:8080/realms/my-realm');
const client = new OpenID.Client({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret',
  redirect_uris: ['http://localhost:3000/callback']
});
```

**cURL - Get Access Token:**
```bash
curl -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=my-client" \
  -d "client_secret=secret" \
  -d "username=user" \
  -d "password=password" \
  -d "grant_type=password"
```

## Health Checks

Keycloak health endpoints:
- **Startup**: `http://localhost:8080/health/live`
- **Ready**: `http://localhost:8080/health/ready`

## Port Mappings

| Service | Container Port | Host Port |
|---------|----------------|-----------|
| Keycloak | 8080 | 8080 |
| PostgreSQL | 5432 | 5432 |

## Troubleshooting

### Keycloak not starting
```bash
# Check logs
podman-compose logs keycloak

# Verify PostgreSQL is healthy
podman-compose ps
```

### Database connection issues
```bash
# Check PostgreSQL logs
podman-compose logs postgres

# Verify credentials in .env
cat .env
```

### Port already in use
```bash
# Find process using port 8080
lsof -i :8080

# Change port in docker-compose.yml:
ports:
  - "8081:8080"  # External:Internal
```

### Reset to Clean State
```bash
# Stop and remove everything
podman-compose down -v

# Start fresh
podman-compose up -d
```

## Production Deployment

For production use:

1. **Change admin password** immediately
2. **Update KC_PROXY** setting based on your reverse proxy
3. **Enable HTTPS**: Set `KC_HTTPS_ENABLED=true` and provide certs
4. **Use environment variables** for sensitive data
5. **Configure backup** for PostgreSQL data
6. **Scale database** with proper resources
7. **Use strong database passwords**

## Security Notes

⚠️ **Development Only**: The current `.env` has weak credentials suitable only for local development.

For production:
- Use strong, randomly generated passwords
- Use external secrets manager
- Enable HTTPS
- Restrict database access
- Implement regular backups
- Monitor authentication logs

## Documentation Links

- [Keycloak Official Docs](https://www.keycloak.org/documentation)
- [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/)
- [OpenID Connect Protocol](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 Specification](https://tools.ietf.org/html/rfc6749)

## Deployment to External Machines

To deploy this Keycloak setup to other servers or machines:

### Option 1: Quick Deploy from GitHub (Recommended)

```bash
# On target machine
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./deploy.sh
```

### Option 2: Manual Deployment

```bash
# Transfer project files to target machine
scp -r /home/sa/repo/idp-setup user@target-machine:~

# On target machine
cd idp-setup
./install-prerequisites.sh  # Install podman, etc.
./configure-network.sh      # Configure network
./start.sh                  # Start services
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Cloud deployment (AWS, Azure, GCP)
- Kubernetes deployment
- Multi-environment setup
- Container image export/import
- Production best practices

## Next Steps

1. ✅ Start Keycloak: `./start.sh`
2. 📝 Create a realm in the Admin Console
3. 👥 Create a user account
4. 🔑 Create an OIDC client
5. 🔗 Integrate with your application
6. 🌐 Deploy to external machines (see [DEPLOYMENT.md](DEPLOYMENT.md))

## Support

For issues or questions:
- Check Keycloak logs: `podman-compose logs keycloak`
- Consult official documentation: https://www.keycloak.org/docs
- Visit community forums: https://github.com/keycloak/keycloak/discussions
