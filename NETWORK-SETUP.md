# Network Configuration Guide

Configure Keycloak for access from other machines on your network.

## Overview

By default, Keycloak listens only on `localhost` (127.0.0.1). To access from other machines, you need to:

1. Configure your machine's IP address
2. Generate SSL certificate for that IP
3. Allow incoming connections (firewall)
4. Access from other machines

## Quick Setup

Run the interactive configuration script:

```bash
./configure-network.sh
```

This will:
1. Detect your machine's IP
2. Ask if you want network access or local-only
3. Add IP to .env file (variable: `KC_HOSTNAME`)
4. Update Nginx configuration

Then:
```bash
./generate-ssl.sh    # Generate certificate for your IP
podman-compose down
podman-compose up -d # Restart with new configuration
```

Done! Access from another machine using your IP.

## Manual Setup

### Step 1: Find Your Machine's IP

**On Linux:**
```bash
hostname -I | awk '{print $1}'
```

**On Mac:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows (WSL2):**
```bash
# From WSL2
hostname -I

# Get Windows IP (for accessing from other machines)
ipconfig.exe | grep "IPv4 Address"
```

Example output: `192.168.1.100`

### Step 2: Configure Environment

Edit `.env`:

```bash
nano .env
```

Find and update:
```bash
KC_HOSTNAME=192.168.1.100    # Your machine's IP
```

### Step 3: Generate SSL Certificate for Your IP

```bash
./generate-ssl.sh
```

When prompted, enter your IP address (not localhost):
```
Enter hostname/IP for certificate: 192.168.1.100
```

This generates SSL certificate valid for that IP.

### Step 4: Restart Keycloak

```bash
podman-compose down
podman-compose up -d
```

### Step 5: Configure Firewall (Optional but Recommended)

Allow incoming HTTPS connections on port 443:

**Ubuntu/Debian (UFW):**
```bash
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp       # For HTTP→HTTPS redirect
sudo ufw status
```

**Fedora/CentOS/RHEL (firewalld):**
```bash
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

**Check if firewall is active:**
```bash
# Ubuntu
sudo ufw status

# RHEL-based
sudo firewall-cmd --state
```

### Step 6: Access from Other Machines

From any computer on the same network:

```
https://192.168.1.100/admin
```

Browser will show certificate warning (expected). Click through to continue.

## Using Hostname Instead of IP

For more user-friendly access, use a hostname instead of IP.

### Method 1: mDNS (Recommended for Local Networks)

Most modern systems support `.local` domains:

```bash
# On your machine
./configure-network.sh
# When prompted, enter: keycloak.local

./generate-ssl.sh
# Enter: keycloak.local

# Access from other machines
https://keycloak.local/admin
```

Works automatically if:
- All machines on same network
- Running macOS or Windows with Bonjour
- Linux with avahi-daemon installed

### Method 2: DNS Record

For proper domain (e.g., keycloak.example.com):

1. Add DNS A record:
   ```
   keycloak.example.com  A  192.168.1.100
   ```

2. Update .env:
   ```bash
   KC_HOSTNAME=keycloak.example.com
   ```

3. Generate certificate:
   ```bash
   ./generate-ssl.sh
   # Enter: keycloak.example.com
   ```

4. Restart:
   ```bash
   podman-compose down
   podman-compose up -d
   ```

5. Access:
   ```
   https://keycloak.example.com/admin
   ```

### Method 3: Local /etc/hosts File

For local machines without DNS:

**On each client machine**, edit `/etc/hosts`:

```bash
# MacOS/Linux
sudo nano /etc/hosts
# Add: 192.168.1.100 keycloak.local

# Windows
notepad C:\Windows\System32\drivers\etc\hosts
# Add: 192.168.1.100 keycloak.local
```

Then access:
```
https://keycloak.local/admin
```

## Production: HTTPS with Real Certificates

For production deployments, replace self-signed certificates with real ones.

### Using Let's Encrypt

For domains accessible from internet:

```bash
# Install certbot
sudo apt install -y certbot

# Get certificate for your domain
sudo certbot certonly --standalone -d keycloak.example.com

# Copy to nginx/ssl/
sudo cp /etc/letsencrypt/live/keycloak.example.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/keycloak.example.com/privkey.pem nginx/ssl/key.pem
sudo chown $(whoami): nginx/ssl/*

# Restart nginx
podman-compose restart nginx
```

### Using Commercial Certificate

If you have a commercial certificate:

```bash
# Copy your certificate files
cp /path/to/your-cert.pem nginx/ssl/cert.pem
cp /path/to/your-key.pem nginx/ssl/key.pem

# Restart nginx
podman-compose restart nginx
```

## Testing Network Access

### From Same Machine (to verify setup)

```bash
# Test from machine running Keycloak
curl -k https://192.168.1.100/health/ready
```

### From Other Machines

```bash
# Test connectivity
curl -k https://192.168.1.100/health/ready

# Open in browser
https://192.168.1.100/admin
```

### Troubleshooting

If you can't access from another machine:

```bash
# 1. Check if Keycloak is running
podman-compose ps

# 2. Check if nginx is listening on correct IP
sudo netstat -tulpn | grep -E "(80|443)"

# 3. Test from localhost first
curl -k https://localhost/health/ready

# 4. Check nginx logs
podman-compose logs nginx

# 5. Check firewall
sudo ufw status          # Ubuntu
sudo firewall-cmd --list-ports  # RHEL

# 6. Verify .env has correct IP
grep KC_HOSTNAME .env
```

## Router Configuration (Advanced)

To access from outside your local network:

### 1. Configure Port Forwarding on Router

Forward external port 443 to machine port 443:
- External Port: 443
- Internal IP: 192.168.1.100
- Internal Port: 443
- Protocol: TCP

### 2. Use Dynamic DNS (if home network)

If your ISP changes your IP:
- Set up Dynamic DNS service (DynDNS, No-IP, etc.)
- Point domain to your dynamic IP
- Update SSL certificate when public IP changes

### 3. Use Real Domain and Certificate

```bash
# Get Let's Encrypt certificate for your public domain
certbot certonly --standalone -d keycloak.yourdomain.com

# Copy to nginx/ssl/
cp /etc/letsencrypt/live/keycloak.yourdomain.com/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/keycloak.yourdomain.com/privkey.pem nginx/ssl/key.pem

# Restart
podman-compose restart nginx
```

### 4. Configure Keycloak for External Domain

Update .env:
```bash
KC_HOSTNAME=keycloak.yourdomain.com
```

Restart:
```bash
podman-compose down && podman-compose up -d
```

## Common Scenarios

### Access from Office Network

1. Find machine IP: `hostname -I`
2. Configure: `./configure-network.sh` → enter IP
3. Generate cert: `./generate-ssl.sh` → enter IP
4. Restart: `podman-compose down && podman-compose up -d`
5. From office, access: `https://192.168.1.100/admin`

### Access from Home and Office

Use hostname instead of IP:

1. Configure: `./configure-network.sh` → enter `keycloak.local`
2. Generate: `./generate-ssl.sh` → enter `keycloak.local`
3. Restart: `podman-compose down && podman-compose up -d`
4. Add to `/etc/hosts` on client machines: `192.168.1.100 keycloak.local`
5. Access: `https://keycloak.local/admin`

### Access from Microservices

If your services are in same Docker network:

```bash
# In your service's docker-compose.yml
services:
  my-service:
    environment:
      KEYCLOAK_URL: https://keycloak:443  # Use service name
```

## Monitoring Network Access

```bash
# View incoming connections
sudo netstat -tupn | grep ESTABLISHED

# Monitor bandwidth
iftop

# Check which services are listening
sudo netstat -tulpn
```

## Security Notes

- Self-signed certificates show warnings (expected)
- For production: use real certificates (Let's Encrypt)
- Firewall: only open ports you need (80, 443)
- HTTPS: always use HTTPS (port 443) in production
- Passwords: change default admin password immediately

## Next Steps

- [Quick Start](QUICKSTART.md) - Full deployment guide
- [Deployment](DEPLOYMENT.md) - Deploy to other servers
- [Keycloak Docs](https://www.keycloak.org/documentation) - Official documentation

---

**Need help?** Check [README.md](README.md#troubleshooting) troubleshooting section.

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

4. **Start Keycloak:**
```bash
podman-compose up -d
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
- Access: https://localhost/admin
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
curl -k https://localhost/
curl -k https://192.168.1.100/  # Using your IP
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
