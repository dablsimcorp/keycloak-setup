# Keycloak Setup on Windows

This guide explains how to run the Keycloak setup on Windows machines.

## ⚠️ Windows Compatibility

**Bash Scripts**: The `.sh` scripts in this repository are designed for Linux/Unix and **will not run natively on Windows**.

**Recommended Options**:
1. **WSL2 (Windows Subsystem for Linux)** - Best option, full compatibility ⭐
2. **Docker Desktop for Windows** - Good alternative
3. **Git Bash + Docker Desktop** - Manual approach
4. **Podman Desktop** - Windows native container runtime

---

## Option 1: WSL2 (Recommended) ⭐

WSL2 provides a complete Linux environment on Windows with full compatibility.

### Setup WSL2

1. **Enable WSL2** (PowerShell as Administrator):
```powershell
wsl --install
```

2. **Restart your computer**

3. **Install Ubuntu** (or your preferred distro):
```powershell
wsl --install -d Ubuntu-22.04
```

4. **Launch Ubuntu** from Start Menu and set up username/password

### Deploy Keycloak in WSL2

```bash
# Inside WSL2 terminal
cd ~

# Clone the repository
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# Deploy
./deploy.sh
```

### Accessing from Windows

Once running in WSL2:
- **From WSL2**: http://localhost:8080/admin
- **From Windows Browser**: http://localhost:8080/admin
- **From Network**: http://YOUR_WINDOWS_IP:8080/admin

**Advantages**:
- ✅ All scripts work perfectly
- ✅ Native Linux performance
- ✅ Full Podman/Docker support
- ✅ Easy to access from Windows
- ✅ Can use Windows VS Code with WSL extension

---

## Option 2: Docker Desktop for Windows

Install Docker Desktop and use docker-compose commands directly.

### Setup Docker Desktop

1. **Download Docker Desktop**:
   - https://www.docker.com/products/docker-desktop

2. **Install and start Docker Desktop**

3. **Enable WSL2 backend** (Settings → General → Use WSL 2 based engine)

### Deploy Keycloak with Docker Desktop

**Using PowerShell or Command Prompt:**

```powershell
# Clone repository
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# Copy environment file
copy .env.example .env

# Edit .env with Notepad
notepad .env

# Start with Docker Compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f keycloak

# Stop services
docker-compose down
```

**Manual Configuration (.env file)**:
```
KC_HOSTNAME=localhost
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=keycloak
```

### Access Keycloak
- **URL**: http://localhost:8080/admin
- **Credentials**: admin / admin

**Note**: Bash scripts (.sh) won't work, but docker-compose commands work directly.

---

## Option 3: Git Bash + Docker Desktop

Use Git Bash for a Unix-like shell experience on Windows.

### Setup

1. **Install Git for Windows** (includes Git Bash):
   - https://git-scm.com/download/win

2. **Install Docker Desktop** (see Option 2)

3. **Launch Git Bash**

### Deploy

```bash
# In Git Bash
cd ~
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

# Copy environment file
cp .env.example .env

# Edit with your favorite editor
vim .env  # or notepad .env

# Try running bash scripts (may have compatibility issues)
./deploy.sh

# If scripts fail, use docker-compose directly
docker-compose up -d
```

**Limitations**:
- Some bash scripts may not work properly
- Better to use docker-compose commands directly
- File path conversions may be needed

---

## Option 4: Podman Desktop for Windows

Podman Desktop is a Windows-native alternative to Docker Desktop.

### Setup Podman Desktop

1. **Download Podman Desktop**:
   - https://podman-desktop.io/downloads

2. **Install Podman Desktop**

3. **Start Podman machine** (creates a WSL2 VM internally)

### Deploy

```powershell
# In PowerShell
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup

copy .env.example .env
notepad .env

# Use podman-compose
podman-compose up -d

# Or use podman directly
podman network create keycloak-network
podman run -d --name keycloak-postgres ...
```

---

## Windows-Specific Instructions

### Accessing Keycloak from Network

To make Keycloak accessible from other machines:

1. **Find your Windows IP**:
```powershell
ipconfig
# Look for IPv4 Address
```

2. **Update .env**:
```
KC_HOSTNAME=192.168.1.100  # Your Windows IP
```

3. **Configure Windows Firewall**:
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Keycloak HTTP" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

4. **Restart Keycloak**:
```powershell
docker-compose down
docker-compose up -d
```

### SSL/HTTPS on Windows

For HTTPS setup on Windows:

**With Docker Desktop:**
```powershell
# Generate self-signed certificate (PowerShell)
New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation cert:\LocalMachine\My

# Or use OpenSSL in Git Bash
cd keycloak-setup/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem

# Start with nginx
docker-compose -f docker-compose.nginx.yml up -d
```

---

## Comparison Table

| Method | Compatibility | Performance | Ease of Use | Recommendation |
|--------|--------------|-------------|-------------|----------------|
| **WSL2** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Best for developers |
| **Docker Desktop** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Best for ease |
| **Git Bash** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Limited |
| **Podman Desktop** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Good alternative |

---

## Quick Start for Windows Users

### Absolute Easiest (Docker Desktop)

```powershell
# 1. Install Docker Desktop from docker.com

# 2. Open PowerShell
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
copy .env.example .env

# 3. Start Keycloak
docker-compose up -d

# 4. Wait 30-60 seconds, then open browser
# http://localhost:8080/admin
# Login: admin / admin
```

### Best Performance (WSL2)

```powershell
# 1. Install WSL2 (Run as Administrator in PowerShell)
wsl --install

# 2. Restart computer

# 3. Open "Ubuntu" from Start Menu
cd ~
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./deploy.sh

# 4. Open Windows browser
# http://localhost:8080/admin
```

---

## Troubleshooting Windows Issues

### Issue: "docker-compose: command not found"

**Solution**: Install Docker Desktop or use `docker compose` (new syntax):
```powershell
docker compose up -d
```

### Issue: Port 8080 already in use

**Check what's using the port**:
```powershell
netstat -ano | findstr :8080
```

**Kill the process** (replace PID):
```powershell
taskkill /PID <process_id> /F
```

**Or change the port** in docker-compose.yml:
```yaml
ports:
  - "8081:8080"  # External:Internal
```

### Issue: Scripts don't run (*.sh)

**Solutions**:
1. Use WSL2 (recommended)
2. Use docker-compose commands directly (skip scripts)
3. Convert scripts to PowerShell (advanced)

### Issue: Can't access from network

**Check**:
1. Windows Firewall is allowing port 8080
2. Docker is binding to 0.0.0.0 not 127.0.0.1
3. Your Windows IP is correct in KC_HOSTNAME

**Allow in firewall**:
```powershell
New-NetFirewallRule -DisplayName "Keycloak" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

### Issue: WSL2 performance slow

**Solution**: Ensure Docker Desktop is using WSL2 backend:
```
Docker Desktop → Settings → General → Use the WSL 2 based engine
```

---

## Windows PowerShell Script (Alternative to Bash)

Create `deploy.ps1` for Windows:

```powershell
# Keycloak Deployment for Windows
Write-Host "🚀 Deploying Keycloak on Windows" -ForegroundColor Green

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create .env if not exists
if (!(Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "✓ Created .env file" -ForegroundColor Green
}

# Start services
Write-Host "Starting services..." -ForegroundColor Yellow
docker-compose up -d

# Wait for startup
Write-Host "Waiting for Keycloak to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Show status
docker-compose ps

Write-Host "`n✅ Keycloak deployed!" -ForegroundColor Green
Write-Host "Access: http://localhost:8080/admin" -ForegroundColor Cyan
Write-Host "Username: admin" -ForegroundColor Cyan
Write-Host "Password: admin" -ForegroundColor Cyan
```

**Usage**:
```powershell
.\deploy.ps1
```

---

## Development with VS Code on Windows

1. **Install VS Code with WSL extension**:
   - Install "Remote - WSL" extension

2. **Open project in WSL**:
```
File → Open Folder → \\wsl$\Ubuntu\home\username\keycloak-setup
```

3. **Use WSL terminal** inside VS Code

4. **All commands work as in Linux**

---

## Production on Windows Server

For Windows Server deployments:

1. **Use Docker Desktop or Podman Desktop**
2. **Run as Windows Service** (Docker Desktop auto-starts)
3. **Configure Windows Firewall properly**
4. **Use nginx on Windows** or IIS as reverse proxy
5. **Consider using Linux VMs** for production (more stable)

---

## Summary

**For Windows Users**:

| Your Situation | Recommended Approach |
|----------------|---------------------|
| Development on laptop/desktop | WSL2 + full scripts |
| Just want it working | Docker Desktop + PowerShell |
| No WSL2 access | Docker Desktop + Git Bash |
| Windows Server | Docker Desktop + manual setup |
| Maximum compatibility | Use a Linux VM |

**Best Practice**: 
Use **WSL2** for the best experience on Windows. It provides full Linux compatibility while being easily accessible from Windows.

---

## Resources

- **WSL2 Installation**: https://learn.microsoft.com/en-us/windows/wsl/install
- **Docker Desktop**: https://docs.docker.com/desktop/install/windows-install/
- **Podman Desktop**: https://podman-desktop.io/docs/installation/windows-install
- **Git for Windows**: https://git-scm.com/download/win

---

## Quick Command Reference

### PowerShell Commands
```powershell
# Start
docker-compose up -d

# Stop
docker-compose down

# Status
docker-compose ps

# Logs
docker-compose logs -f keycloak

# Restart
docker-compose restart keycloak

# Full rebuild
docker-compose down -v
docker-compose up -d
```

### WSL2 Commands
```bash
# Same as Linux
./deploy.sh
./start.sh
./stop.sh
./status.sh
```

---

**Need Help?** Check the main documentation or open an issue on GitHub.
