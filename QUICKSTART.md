# Quick Start Guide

Get Keycloak running in 5 minutes with HTTPS enabled.

## Prerequisites

Check you have Podman (or Docker):
```bash
podman --version    # Should show 3.0+
# or
docker --version
```

If not installed, run:
```bash
./install-prerequisites.sh
```

## Step 1: Install podman-compose (if needed)

```bash
# Check if installed
podman-compose --version

# If not, install via curl
sudo curl -o /usr/local/bin/podman-compose \
  https://raw.githubusercontent.com/containers/podman-compose/main/podman-compose
sudo chmod +x /usr/local/bin/podman-compose

# Verify
podman-compose --version
```

## Step 2: Generate SSL Certificate

```bash
./generate-ssl.sh
```

You'll be prompted:
- Press `y` to generate certificate
- Enter your machine's IP or hostname (or press Enter for localhost)

Example output:
```
Certificate generated: nginx/ssl/cert.pem
Key generated: nginx/ssl/key.pem
```

## Step 3: Configure Environment (Optional)

Default configuration works locally. To customize:

```bash
cp .env.example .env
nano .env  # Edit as needed
```

Common settings:
```bash
KC_HOSTNAME=192.168.1.100        # Your machine IP
KEYCLOAK_ADMIN_PASSWORD=secure123
POSTGRES_PASSWORD=dbpass123
```

## Step 4: Start Keycloak

```bash
podman-compose up -d
```

This starts three services:
- **keycloak** - Identity provider
- **postgres** - Database
- **nginx** - HTTPS reverse proxy

Wait 10-15 seconds for services to fully initialize.

## Step 5: Verify Services Running

```bash
podman-compose ps
```

Expected output (all healthy):
```
CONTAINER ID  IMAGE                 STATUS
...           keycloak:latest       Up 2 minutes
...           postgres:16-alpine    Up 2 minutes
...           nginx:alpine          Up 2 minutes
```

Or use health check:
```bash
./status.sh
```

## Step 6: Access Keycloak

Open browser to:

```
https://localhost/admin
```

Login with:
- **Username**: `admin`
- **Password**: `admin`

### Browser Certificate Warning

⚠️ You'll see a warning about certificate not being trusted. This is normal for self-signed certificates.

- **Chrome**: Click "Advanced" → "Proceed to localhost"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Safari**: Click "Show Details" → "Visit This Website"

## Common Tasks

### View Logs
```bash
podman-compose logs -f keycloak     # Keycloak logs
podman-compose logs -f nginx        # Nginx logs
podman-compose logs -f postgres     # Database logs
```

### Stop Services
```bash
podman-compose down
```

Services will stop and remove containers. Data persists in volumes.

### Restart Services
```bash
podman-compose down
podman-compose up -d
```

### Reset to Default State
```bash
# Remove containers and volumes (WARNING: Deletes all data)
podman-compose down -v

# Remove certificates
rm -rf nginx/ssl/*

# Start fresh
./generate-ssl.sh
podman-compose up -d
```

## Troubleshooting

### Port Already in Use

Error: `Error starting userland proxy: listen tcp 0.0.0.0:80: bind: permission denied`

Solutions:
```bash
# Check what's using port 80/443
sudo lsof -i :80
sudo lsof -i :443

# Stop the service using those ports
# Or use different ports in docker-compose.yml
```

### Containers Not Starting

Check logs:
```bash
podman-compose logs
```

Common issues:
- **Permission denied**: Run with `sudo podman-compose up -d`
- **Image not found**: Run `podman pull` for missing images
- **Port conflict**: See "Port Already in Use" above

### Slow Startup

Keycloak can take 15-30 seconds to initialize on first run. Be patient:
```bash
# Check progress
podman-compose logs -f keycloak | grep -i "ready\|started\|listening"
```

### Can't Access from Other Machines

By default, Keycloak listens only on localhost. To allow network access:

1. Find your machine's IP:
   ```bash
   hostname -I
   ```

2. Configure for network:
   ```bash
   ./configure-network.sh
   ```

3. Update SSL certificate:
   ```bash
   ./generate-ssl.sh
   ```

4. Restart:
   ```bash
   podman-compose down
   podman-compose up -d
   ```

5. Access from other machine:
   ```
   https://192.168.1.100/admin
   ```

See [NETWORK-SETUP.md](NETWORK-SETUP.md) for detailed networking guide.

## Windows Users

Use WSL2 (Windows Subsystem for Linux). See [WINDOWS.md](WINDOWS.md).

## Next Steps

1. **Change Admin Password**
   - In Keycloak: Account >> Password >> Change Password
   - Change default credentials immediately!

2. **Create a Realm**
   - In Keycloak: Select realm dropdown >> Create Realm
   - Realms isolate users and applications

3. **Create OAuth 2.0 Client**
   - Navigate to: Clients >> Create Client
   - Configure for your application

4. **Set Up User Federation** (Optional)
   - Connect to LDAP, Active Directory, or other user sources

5. **Enable 2FA** (Recommended)
   - In Keycloak: Authentication >> Required Actions
   - Enable TOTP or WebAuthn

6. **Customize Login Theme** (Optional)
   - Upload custom CSS/HTML for branded login pages

## Helpful Commands

```bash
# Everything
podman-compose up -d        # Start all services
podman-compose down         # Stop all services
podman-compose ps           # Show status
podman-compose logs -f      # Follow logs
podman-compose restart      # Restart services

# Individual containers
podman logs -f keycloak
podman exec -it keycloak bash
podman restart keycloak

# Health checks
curl -k https://localhost/health/ready
./status.sh

# Configuration
./configure-network.sh      # Network setup wizard
./generate-ssl.sh           # Generate SSL certificates

# Cleanup
podman-compose down -v      # Stop and remove volumes
rm -rf nginx/ssl/*          # Remove certificates
```

## Where to Go From Here

- **[README.md](README.md)** - Full project overview
- **[NETWORK-SETUP.md](NETWORK-SETUP.md)** - Configure external access
- **[WINDOWS.md](WINDOWS.md)** - Windows/WSL2 setup
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deploy to other servers
- **[Keycloak Docs](https://www.keycloak.org/documentation)** - Official documentation

---

**Having issues?** Check the Troubleshooting section above or consult [README.md](README.md#troubleshooting).
