#!/bin/bash

# Install prerequisites for Keycloak setup
# Supports Ubuntu/Debian and RHEL/CentOS/Fedora

set -e

echo "🔧 Installing Keycloak Prerequisites"
echo "====================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "❌ Cannot detect OS"
    exit 1
fi

echo "📋 Detected OS: $OS $VERSION"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
    echo "ℹ️  Will use sudo for system installations"
fi

echo "📦 Installing required packages..."
echo ""

case $OS in
    ubuntu|debian)
        echo "Installing for Ubuntu/Debian..."
        $SUDO apt update
        $SUDO apt install -y \
            podman \
            podman-compose \
            curl \
            wget \
            net-tools \
            openssl \
            ca-certificates
        ;;
    
    rhel|centos|fedora|rocky|almalinux)
        echo "Installing for RHEL/CentOS/Fedora..."
        $SUDO dnf install -y \
            podman \
            podman-compose \
            curl \
            wget \
            net-tools \
            openssl \
            ca-certificates
        ;;
    
    *)
        echo "❌ Unsupported OS: $OS"
        echo "Please manually install: podman, podman-compose, curl, openssl"
        exit 1
        ;;
esac

echo ""
echo "✅ Packages installed successfully"
echo ""

# Verify installations
echo "🔍 Verifying installations..."
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -1)
        echo "  ✓ $1: $VERSION"
        return 0
    else
        echo "  ✗ $1: Not found"
        return 1
    fi
}

ALL_OK=true
check_command podman || ALL_OK=false
check_command podman-compose || ALL_OK=false
check_command curl || ALL_OK=false
check_command openssl || ALL_OK=false

echo ""

if [ "$ALL_OK" = true ]; then
    echo "✅ All prerequisites installed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "  1. Configure network: ./configure-network.sh"
    echo "  2. Start Keycloak:    ./start.sh"
    echo "  3. Access console:    http://localhost:8080/admin"
else
    echo "⚠️  Some prerequisites are missing. Please install them manually."
    exit 1
fi

# Check if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo ""
    echo "ℹ️  WSL detected. Note:"
    echo "  - Podman works in WSL2"
    echo "  - You may need to configure systemd or run rootless mode"
fi

# Enable podman socket if systemd is available
if command -v systemctl &> /dev/null; then
    echo ""
    echo "🔌 Enabling Podman socket (for Docker compatibility)..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
fi

echo ""
echo "🎉 Setup complete! You're ready to deploy Keycloak."
