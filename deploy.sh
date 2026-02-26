#!/bin/bash

# Quick deployment script for external machines
# Run this on a fresh machine to set up Keycloak

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Keycloak Quick Deployment"
echo "============================="
echo ""
echo "This script will:"
echo "  1. Install prerequisites (podman, podman-compose, etc.)"
echo "  2. Configure network settings"
echo "  3. Start Keycloak and PostgreSQL"
echo ""

read -p "Continue with deployment? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/3: Installing Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "./install-prerequisites.sh" ]; then
    chmod +x ./install-prerequisites.sh
    ./install-prerequisites.sh
else
    echo "⚠️  install-prerequisites.sh not found, skipping..."
    echo "Make sure podman and podman-compose are installed."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/3: Configuring Network"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect IP
PRIMARY_IP=$(hostname -I | awk '{print $1}')
echo "📍 Detected IP: $PRIMARY_IP"
echo ""
echo "Choose access mode:"
echo "  1) Network access (IP: $PRIMARY_IP)"
echo "  2) Custom hostname/domain"
echo "  3) Local only (localhost)"
echo ""
read -p "Enter choice [1-3]: " access_choice

case $access_choice in
    1)
        KC_HOST="$PRIMARY_IP"
        ;;
    2)
        read -p "Enter hostname or domain: " KC_HOST
        ;;
    3)
        KC_HOST="localhost"
        ;;
    *)
        KC_HOST="$PRIMARY_IP"
        echo "Using default: $PRIMARY_IP"
        ;;
esac

# Update .env file
if [ -f ".env" ]; then
    if grep -q "^KC_HOSTNAME=" .env; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^KC_HOSTNAME=.*|KC_HOSTNAME=$KC_HOST|" .env
        else
            sed -i "s|^KC_HOSTNAME=.*|KC_HOSTNAME=$KC_HOST|" .env
        fi
    else
        echo "KC_HOSTNAME=$KC_HOST" >> .env
    fi
    echo "✓ Updated KC_HOSTNAME to $KC_HOST"
else
    echo "⚠️  .env file not found, creating one..."
    cat > .env << EOF
# Keycloak Configuration
KC_HOSTNAME=$KC_HOST
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin

# PostgreSQL
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=keycloak

# Proxy settings
KC_PROXY=edge
KC_HOSTNAME_STRICT=false
KC_HTTP_ENABLED=true
KC_HTTP_PORT=8080
EOF
    echo "✓ Created .env file"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/3: Starting Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create network and volume
echo "Creating network and storage..."
podman network create idp-setup 2>/dev/null || echo "Network already exists"
podman volume create postgres-data 2>/dev/null || echo "Volume already exists"

# Start PostgreSQL
echo ""
echo "Starting PostgreSQL..."
podman run -d \
  --name keycloak-postgres \
  --network idp-setup \
  -e POSTGRES_DB=keycloak \
  -e POSTGRES_USER=keycloak \
  -e POSTGRES_PASSWORD=keycloak \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  docker.io/library/postgres:16-alpine 2>/dev/null || echo "PostgreSQL already running"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 5

# Start Keycloak
echo ""
echo "Starting Keycloak..."
podman run -d \
  --name keycloak \
  --network idp-setup \
  -e KC_DB=postgres \
  -e KC_DB_URL=jdbc:postgresql://keycloak-postgres:5432/keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=keycloak \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME=$KC_HOST \
  -e KC_HTTP_ENABLED=true \
  -p 8080:8080 \
  quay.io/keycloak/keycloak:latest start-dev 2>/dev/null || echo "Keycloak already running"

echo ""
echo "⏳ Waiting for Keycloak to initialize (30-60 seconds)..."
sleep 20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Service Status:"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🔗 Access Points:"
if [ "$KC_HOST" = "localhost" ]; then
    echo "   Admin Console: http://localhost:8080/admin"
else
    echo "   From this machine:    http://localhost:8080/admin"
    echo "   From other machines:  http://$KC_HOST:8080/admin"
fi
echo ""
echo "👤 Default Credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Wait 30-60 seconds for Keycloak to fully start"
echo "   2. Access the admin console (URLs above)"
echo "   3. Login and change the admin password immediately!"
echo "   4. Configure firewall if needed: sudo ufw allow 8080/tcp"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start:   ./QUICKSTART.md"
echo "   - Network Setup: ./NETWORK-SETUP.md"
echo "   - Deployment:    ./DEPLOYMENT.md"
echo ""
echo "🔧 Useful Commands:"
echo "   Check status:  podman ps"
echo "   View logs:     podman logs -f keycloak"
echo "   Stop:          podman stop keycloak keycloak-postgres"
echo "   Restart:       podman restart keycloak"
echo ""
