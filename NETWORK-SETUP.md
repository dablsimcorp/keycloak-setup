# Network Access Configuration Guide

This guide explains how to expose your Keycloak instance to other machines on your network or the internet.

## Quick Setup: Network Access

### 1. Auto-Configure for Network Access

Run the interactive configuration script:

```bash
./configure-network.sh
```

This will:
- Detect your machine's IP address
- Let you choose local-only or network access mode
- Update configuration automatically
- Optionally restart Keycloak with new settings

### 2. Manual Configuration

Edit `.env` file:

```bash
# For network access, set to your machine's IP or domain
KC_HOSTNAME=192.168.1.100  # Replace with your actual IP
```

Restart Keycloak:

```bash
podman stop keycloak && podman rm keycloak
./start.sh
```

### 3. Configure Firewall

Allow incoming connections on port 8080:

**Ubuntu/Debian (UFW):**
```bash
sudo ufw allow 8080/tcp
sudo ufw status
```

**RHEL/CentOS/Fedora (firewalld):**
```bash
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

**Check if firewall is active:**
```bash
sudo ufw status          # Ubuntu/Debian
sudo firewall-cmd --state  # RHEL/CentOS
```

### 4. Find Your IP Address

```bash
# Primary IP
hostname -I | awk '{print $1}'

# Or show all network interfaces
ip addr show | grep "inet "
```

### 5. Test Access

From another machine on the same network:

```bash
# Test connectivity
curl http://192.168.1.100:8080/

# Open in browser
http://192.168.1.100:8080/admin
```

---

## Advanced: HTTPS with Nginx Reverse Proxy

For production or secure testing, use nginx as a reverse proxy with SSL/TLS.

### Setup with Self-Signed Certificate (Development)

1. **Generate SSL certificate:**
```bash
./generate-ssl.sh
```

2. **Edit `nginx/nginx.conf`:**
   - Uncomment the HTTPS server block
   - Update `server_name` with your hostname/IP
   - Uncomment the HTTP to HTTPS redirect

3. **Update `.env`:**
```bash
KC_HOSTNAME=your-hostname.local
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

4. **Start with nginx:**
```bash
podman-compose -f docker-compose.nginx.yml up -d
```

5. **Access:**
   - HTTP: http://your-hostname.local (redirects to HTTPS)
   - HTTPS: https://your-hostname.local

**Note:** You'll see a browser warning for self-signed certificates. Click "Advanced" → "Proceed" to continue.

### Setup with Let's Encrypt (Production)

1. **Install certbot:**
```bash
# Ubuntu/Debian
sudo apt install certbot

# RHEL/CentOS
sudo dnf install certbot
```

2. **Get SSL certificate:**
```bash
# Make sure ports 80 and 443 are open
sudo certbot certonly --standalone -d keycloak.yourdomain.com

# Certificates will be in /etc/letsencrypt/live/keycloak.yourdomain.com/
```

3. **Copy certificates:**
```bash
sudo cp /etc/letsencrypt/live/keycloak.yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/keycloak.yourdomain.com/privkey.pem nginx/ssl/key.pem
sudo chown $USER:$USER nginx/ssl/*.pem
```

4. **Configure nginx and start:**
```bash
# Update nginx/nginx.conf with your domain
# Update .env with KC_HOSTNAME=keycloak.yourdomain.com
podman-compose -f docker-compose.nginx.yml up -d
```

5. **Setup auto-renewal:**
```bash
# Add to crontab
sudo crontab -e

# Add this line (renews every day at 2am)
0 2 * * * certbot renew --quiet --deploy-hook "cp /etc/letsencrypt/live/keycloak.yourdomain.com/*.pem /path/to/idp-setup/nginx/ssl/ && podman restart keycloak-nginx"
```

---

## Configuration Options

### Environment Variables (.env)

```bash
# Hostname - REQUIRED for network access
KC_HOSTNAME=localhost           # Local only
KC_HOSTNAME=192.168.1.100      # Network access by IP
KC_HOSTNAME=keycloak.local     # Network access by hostname
KC_HOSTNAME=kc.example.com     # Internet access with domain

# Admin credentials (CHANGE THESE!)
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=your-secure-password

# Database credentials
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=your-db-password

# Proxy mode
KC_PROXY=edge                  # Use with reverse proxy
KC_PROXY=none                  # Direct access

# Ports (nginx setup only)
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

---

## Network Scenarios

### Scenario 1: Local Development Only
```bash
KC_HOSTNAME=localhost
```
- Access: http://localhost:8080/admin
- No firewall configuration needed
- Most secure (not exposed to network)

### Scenario 2: LAN Access (Home/Office Network)
```bash
KC_HOSTNAME=192.168.1.100  # Your machine's IP
```
- Access from any device on the same network
- Requires: Firewall configured to allow port 8080
- Security: Ensure your network is trusted

### Scenario 3: Internet Access with Domain
```bash
KC_HOSTNAME=keycloak.yourdomain.com
```
- Access from anywhere via domain name
- Requires: 
  - Domain name pointing to your server
  - Port forwarding on router (if behind NAT)
  - SSL certificate (Let's Encrypt)
  - Nginx reverse proxy
  - Strong admin password
- For production use only with proper security

### Scenario 4: Dynamic DNS (Home Server)
```bash
KC_HOSTNAME=myhome.dyndns.org
```
- Access via dynamic DNS hostname
- Requires:
  - Dynamic DNS service (DynDNS, No-IP, etc.)
  - Port forwarding
  - SSL certificate
  - Keep software updated

---

## Port Forwarding (Router Configuration)

If you want to expose Keycloak to the internet:

1. **Access your router** (usually http://192.168.1.1 or http://192.168.0.1)

2. **Find Port Forwarding section** (may be called "NAT", "Virtual Server", or "Applications")

3. **Add port forwarding rule:**
   - External Port: 443 (HTTPS)
   - Internal IP: 192.168.1.100 (your machine's IP)
   - Internal Port: 443
   - Protocol: TCP

4. **Optional: Forward HTTP (for Let's Encrypt):**
   - External Port: 80
   - Internal IP: 192.168.1.100
   - Internal Port: 80
   - Protocol: TCP

---

## Security Checklist

Before exposing Keycloak to a network:

- [ ] Change default admin password
- [ ] Use strong database password
- [ ] Enable HTTPS (required for production)
- [ ] Configure KC_HOSTNAME correctly
- [ ] Set up firewall rules
- [ ] Use reverse proxy (nginx) for production
- [ ] Enable rate limiting
- [ ] Keep Keycloak and OS updated
- [ ] Monitor access logs
- [ ] Regular security audits
- [ ] Restrict admin console access by IP (if possible)
- [ ] Enable 2FA for admin accounts

---

## Troubleshooting

### Can't access from other machine

1. **Check Keycloak is running:**
```bash
podman ps | grep keycloak
```

2. **Check hostname configuration:**
```bash
grep KC_HOSTNAME .env
```

3. **Check firewall:**
```bash
sudo ufw status           # Ubuntu
sudo firewall-cmd --list-all  # RHEL
```

4. **Test port is open:**
```bash
# From another machine
telnet 192.168.1.100 8080
# Or
nc -zv 192.168.1.100 8080
```

5. **Check from local machine first:**
```bash
curl http://localhost:8080/
curl http://192.168.1.100:8080/  # Using your IP
```

### SSL Certificate Errors

- **Self-signed certificate warning:** Normal, click "Advanced" → "Proceed"
- **Certificate name mismatch:** Ensure KC_HOSTNAME matches certificate CN/SAN
- **Certificate expired:** Renew with `certbot renew` or regenerate self-signed cert

### Keycloak Shows Wrong URLs

This happens when KC_HOSTNAME is not set correctly:

1. Stop Keycloak
2. Update KC_HOSTNAME in .env
3. Clear browser cache
4. Restart Keycloak
5. Clear Keycloak's cache if needed

---

## Architecture Diagrams

### Direct Access (Development)
```
Client → Firewall → Keycloak:8080 → PostgreSQL
```

### With Nginx Reverse Proxy (Production)
```
Client → Firewall → Nginx:443 (HTTPS) → Keycloak:8080 → PostgreSQL
```

---

## Quick Commands Reference

```bash
# Configure for network
./configure-network.sh

# Generate SSL certificate
./generate-ssl.sh

# Start with direct access
./start.sh

# Start with nginx proxy
podman-compose -f docker-compose.nginx.yml up -d

# Stop services
./stop.sh

# Check status
./status.sh

# View logs
podman logs -f keycloak
podman-compose logs -f keycloak

# Restart with new config
podman restart keycloak
```

---

## Support

For detailed Keycloak configuration, see official docs:
- https://www.keycloak.org/server/hostname
- https://www.keycloak.org/server/reverseproxy
