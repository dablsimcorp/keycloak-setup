# Keycloak Setup on Windows

This guide explains how to run the Keycloak setup on Windows machines using WSL2.

## ⚠️ Windows Compatibility

**Bash Scripts**: The `.sh` scripts in this repository are designed for Linux/Unix and **require WSL2 on Windows**.

---

## WSL2 (Required on Windows)

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
- ✅ Easy to access from Windows
- ✅ Can use Windows VS Code with WSL extension

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

Use WSL2 and run the standard Linux SSL helper:

```bash
./generate-ssl.sh
podman-compose -f docker-compose.nginx.yml up -d
```

---

## Quick Start for Windows Users (WSL2)

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

**Solution**: Use WSL2. The scripts are Linux-only.

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

**Solution**: Ensure you are using WSL2 and have adequate RAM/CPU assigned to WSL.

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

**Windows Support**: WSL2 is required for this repository. It provides full Linux compatibility and supports all scripts.

---

## Resources

- **WSL2 Installation**: https://learn.microsoft.com/en-us/windows/wsl/install
- **Git for Windows**: https://git-scm.com/download/win

---

## Quick Command Reference

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
