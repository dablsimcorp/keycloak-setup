# Quick Start Guide - Keycloak with Podman/Docker

This guide provides step-by-step instructions to run Keycloak locally.

## Prerequisites

Make sure you have one of these installed:
- **Podman** 3.0+ (recommended)
- **Docker** 20.0+ with Docker Desktop or Docker Daemon

## Option 1: Using Podman (Recommended)

### Step 1: Check Podman Installation
```bash
podman --version
podman ps
```

### Step 2: Start Services with Podman Compose

First, install podman-compose if not available:
```bash
# On most Linux systems
curl -o /usr/local/bin/podman-compose https://raw.githubusercontent.com/containers/podman-compose/main/podman-compose
chmod +x /usr/local/bin/podman-compose
```

Then start the services:
```bash
cd /home/sa/repo/idp-setup
podman-compose up -d
```

### Step 3: Verify Services Are Running
```bash
podman-compose ps
```

### Step 4: Access Keycloak
- **URL**: http://localhost:8080
- **Admin Console**: http://localhost:8080/admin
- **Username**: admin
- **Password**: admin

### Step 5: View Logs
```bash
podman-compose logs -f keycloak
```

### Step 6: Stop Services
```bash
podman-compose down
```

---

## Option 2: Using Docker Compose

### Step 1: Start Docker Service (if not running)
```bash
# On Linux with systemd
sudo systemctl start docker

# Or if using Docker Desktop, launch the application
```

### Step 2: Start Containers
```bash
cd /home/sa/repo/idp-setup
sudo docker-compose up -d
```

### Step 3: Verify Services
```bash
sudo docker-compose ps
```

### Step 4: Access Keycloak
- **URL**: http://localhost:8080
- **Admin Console**: http://localhost:8080/admin
- **Username**: admin
- **Password**: admin

### Step 5: View Logs
```bash
sudo docker-compose logs -f keycloak
```

### Step 6: Stop Services
```bash
sudo docker-compose down
```

---

## Option 3: Using Helper Scripts

We've provided simple shell scripts to manage Keycloak:

### Start Keycloak
```bash
./start.sh
```

### Check Status
```bash
./status.sh
```

### Stop Keycloak
```bash
./stop.sh
```

---

## Common Tasks

### Access Keycloak Admin Console
1. Navigate to: http://localhost:8080/admin
2. Login with:
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
5. Configure Redirect URIs: `http://localhost:3000/*`
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
# Check Docker/Podman logs
journalctl -u docker -f          # Docker logs
journalctl -u podman -f          # Podman logs (if available)

# Try starting with verbose output
docker-compose up --verbose

# OR with Podman
podman-compose up --verbose
```

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080
sudo lsof -i :8080

# Kill process (replace PID)
kill -9 <PID>

# OR modify the port in docker-compose.yml
# Change: ports: - "8081:8080"
```

### PostgreSQL Connection Issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres
podman-compose logs postgres

# Connect to PostgreSQL directly
psql -h localhost -U keycloak -d keycloak
# Password: keycloak
```

### Reset Everything
```bash
# Remove all containers and data
docker-compose down -v
podman-compose down -v

# Then restart fresh
docker-compose up -d
podman-compose up -d
```

---

## Health Checks

Verify services are healthy:

```bash
# Keycloak health
curl http://localhost:8080/health/ready
# Expected output: {"status":"UP"}

# PostgreSQL connectivity
nc -zv localhost 5432
# Expected output: Connection succeeded
```

---

## Next Steps

After Keycloak is running:

1. ✅ Access http://localhost:8080/admin
2. 📝 Create a new realm for your application
3. 👥 Create test users
4. 🔑 Create OIDC clients for your apps
5. 🔗 Integrate your application using OIDC endpoints

---

## Integration Examples

### Get Configuration
```bash
curl http://localhost:8080/realms/my-realm/.well-known/openid-configuration
```

### Get Access Token (Example)
```bash
curl -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
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

const config = await OpenID.discovery('http://localhost:8080/realms/my-realm');
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
