# Windows Setup Guide

Run Keycloak on Windows using WSL2 (Windows Subsystem for Linux).

## ⚠️ Important

This repository is designed for Linux. On Windows, you must use **WSL2**, which provides a full Linux environment.

**Native Windows (without WSL2)**: Not supported. PowerShell/Batch scripts not provided.

## What is WSL2?

WSL2 is a lightweight Linux virtual machine integrated into Windows. It allows you to:
- Run Linux applications natively on Windows
- Use bash scripts and Docker/Podman
- Share files between Windows and Linux
- Access Linux services from Windows browser

## Installation

### Step 1: Enable WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This installs WSL2 and Ubuntu automatically.

### Step 2: Install Ubuntu (if not already installed)

```powershell
# List available distributions
wsl --list --online

# Install Ubuntu 22.04 (recommended)
wsl --install -d Ubuntu-22.04

# Or use latest Ubuntu
wsl --install -d Ubuntu
```

### Step 3: Launch Ubuntu

Open PowerShell or Command Prompt and run:
```powershell
wsl
```

Or search for "Ubuntu" in Start Menu.

### Step 4: Set Username and Password

First time you launch Ubuntu, you'll be prompted to create user account:
```
Enter new UNIX username: your_username
Enter new UNIX password: your_password
Retype new UNIX password: your_password
```

## Deploy Keycloak

Inside WSL2 Ubuntu terminal:

### Step 1: Install Git (if needed)

```bash
sudo apt update
sudo apt install -y git
```

### Step 2: Clone Repository

```bash
cd ~
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
```

### Step 3: Install Podman/Docker

```bash
./install-prerequisites.sh
```

This installs Podman and podman-compose automatically.

### Step 4: Deploy

```bash
# Generate SSL certificate
./generate-ssl.sh

# Start services
podman-compose up -d
```

### Step 5: Access from Windows

In Windows browser, navigate to:
```
https://localhost/admin
```

Login:
- **Username**: `admin`
- **Password**: `admin`

That's it! WSL2 handles the networking automatically.

## Accessing from Other Windows Applications

### From VS Code

Install [Remote - WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl):

1. Click Remote indicator (bottom left)
2. Select "Connect to WSL"
3. Open folder: `/home/your_username/keycloak-setup`

### From Windows Terminal

You can open WSL2 terminal in Windows Terminal:

1. Install [Windows Terminal](https://apps.microsoft.com/detail/windows-terminal/9N0DX20HK701)
2. It automatically adds Ubuntu profile
3. Select "Ubuntu" from dropdown to launch

### From PowerShell

Run Linux commands from PowerShell:
```powershell
wsl podman-compose up -d
wsl ./status.sh
```

## Accessing from Network

By default, Keycloak runs on `localhost` inside WSL2 and is accessible from Windows on the same machine, but **not from other machines** on your network.

To access from other machines ([see NETWORK-SETUP.md](NETWORK-SETUP.md) for details):

```bash
# Inside WSL2
./configure-network.sh
./generate-ssl.sh
podman-compose down
podman-compose up -d
```

Then access from other machines using Windows machine's IP.

## Useful WSL Commands

### From PowerShell (Windows Terminal)

```powershell
# Start WSL
wsl

# List WSL distributions
wsl --list --verbose

# Stop all WSL services
wsl --shutdown

# Restart WSL
wsl --shutdown && wsl

# Check WSL version
wsl --version

# Update WSL
wsl --update
```

### From WSL (Ubuntu Terminal)

```bash
# Check if system is WSL2
wsl.exe --version

# Get Windows IP address (for accessing Windows from WSL)
ipconfig.exe | grep "IPv4 Address"

# Access Windows files from WSL
cd /mnt/c/Users/YourName/Documents
```

## File Access

### From WSL to Windows

Files in Windows are available at `/mnt/C/`:
```bash
# Access Windows Documents
cd /mnt/c/Users/YourName/Documents

# Copy files to WSL home
cp /mnt/c/path/to/file ~/keycloak-setup/
```

### From Windows to WSL

WSL2 filesystem is available at `\\wsl$\Ubuntu\` in File Explorer:

1. Open File Explorer
2. Type: `\\wsl$\Ubuntu\home\your_username\keycloak-setup`
3. Browse files and folders directly

## Performance Tips

WSL2 runs much faster on **Windows 11** vs Windows 10.

### For Windows 10:

- Use WSL2 disk for project files (not `/mnt/c/` Windows disk)
- Keep heavy operations in WSL filesystem
- Avoid frequent cross-filesystem I/O

### For Windows 11:

- Performance is excellent, minimal overhead
- Can use either WSL disk or Windows disk
- Use WSL home directory: `~/keycloak-setup`

## Troubleshooting

### WSL2 Not Installed

```powershell
# Check if WSL is installed
wsl --version

# If not installed, run
wsl --install
```

### Podman Not Found

```bash
# Inside WSL2 Ubuntu
./install-prerequisites.sh
```

### Services Not Starting

```bash
# Check if containers are running
podman-compose ps

# View logs
podman-compose logs keycloak

# Try with sudo
sudo podman-compose up -d
```

### Can't Access from Windows Browser

```bash
# Inside WSL2, check if nginx is running
podman-compose logs nginx

# Check if port 443 is listening
sudo netstat -tulpn | grep 443

# Try accessing directly
curl -k https://localhost/health/ready
```

### Slow Performance

This is normal on Windows 10. WSL2 can be slower than bare metal Linux.

Solutions:
- Upgrade to Windows 11 (much faster)
- Keep project files in WSL filesystem (`~/`), not Windows disk
- Close unnecessary applications

### Out of Disk Space

WSL2 can consume significant disk space. Check and manage:

```bash
# Check WSL disk usage
df -h

# Find large files
du -sh ~/*

# List Docker/Podman images
podman images

# Remove unused images
podman image prune
```

## Common Workflows

### Daily Development

```bash
# Start WSL
wsl

# Navigate to project
cd ~/keycloak-setup

# Check status
./status.sh

# View logs
podman-compose logs -f keycloak
```

### Making Changes

```bash
# Edit files in VS Code with Remote-WSL extension
code .

# Apply changes
podman-compose restart keycloak

# Check logs
podman-compose logs keycloak
```

### Stopping/Starting Services

```bash
# Stop
podman-compose down

# Start again
podman-compose up -d

# Full restart
podman-compose down && podman-compose up -d
```

## Advanced: Docker Instead of Podman

WSL2 supports both Docker and Podman. If you prefer Docker:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Then use docker-compose instead of podman-compose
docker-compose up -d
```

## Next Steps

1. **Change Admin Password** - In Keycloak, change default credentials
2. **Create Realm** - Set up a new realm for your applications
3. **Configure Clients** - Register OAuth 2.0 / OIDC clients
4. **For Network Access** - See [NETWORK-SETUP.md](NETWORK-SETUP.md)

## Resources

- [WSL2 Official Docs](https://docs.microsoft.com/en-us/windows/wsl/)
- [Keycloak Quick Start](QUICKSTART.md)
- [Network Configuration](NETWORK-SETUP.md)

---

**WSL2 is fully supported. Make sure you're using WSL2 (not WSL1).**
