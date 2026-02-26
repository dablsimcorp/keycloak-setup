#!/bin/bash

# Configure Keycloak for network access
# This script detects your machine's IP and configures Keycloak to be accessible from other machines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🌐 Keycloak Network Configuration"
echo "=================================="
echo ""

# Detect primary IP address
PRIMARY_IP=$(hostname -I | awk '{print $1}')

if [ -z "$PRIMARY_IP" ]; then
    echo "❌ Could not detect IP address"
    exit 1
fi

echo "📍 Detected IP address: $PRIMARY_IP"
echo ""
echo "Select configuration mode:"
echo "  1) Local only (localhost) - accessible only from this machine"
echo "  2) Network access (IP) - accessible from other machines on the network"
echo "  3) Custom hostname - enter your own hostname/domain"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        HOSTNAME="localhost"
        echo "✓ Configured for local access only"
        ;;
    2)
        HOSTNAME="$PRIMARY_IP"
        echo "✓ Configured for network access at $PRIMARY_IP"
        ;;
    3)
        read -p "Enter hostname (e.g., keycloak.yourdomain.com): " HOSTNAME
        echo "✓ Configured for custom hostname: $HOSTNAME"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Update .env file
if grep -q "^KC_HOSTNAME=" .env; then
    # Update existing line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^KC_HOSTNAME=.*|KC_HOSTNAME=$HOSTNAME|" .env
    else
        sed -i "s|^KC_HOSTNAME=.*|KC_HOSTNAME=$HOSTNAME|" .env
    fi
    echo "✓ Updated KC_HOSTNAME in .env"
else
    # Append if not exists
    echo "KC_HOSTNAME=$HOSTNAME" >> .env
    echo "✓ Added KC_HOSTNAME to .env"
fi

echo ""
echo "📋 Configuration Summary"
echo "=================================="
echo "Hostname:     $HOSTNAME"
echo "PostgreSQL:   localhost:5432 (not exposed externally)"
echo "Keycloak:     http://$HOSTNAME:8080"
echo "Admin Console: http://$HOSTNAME:8080/admin"
echo ""

# Check if services are running
if command -v podman &> /dev/null; then
    if podman ps | grep -q keycloak; then
        echo "⚠️  Keycloak is currently running with old configuration"
        echo ""
        read -p "Restart Keycloak with new settings? [y/N]: " restart
        if [[ "$restart" =~ ^[Yy]$ ]]; then
            echo "🔄 Restarting Keycloak..."
            podman stop keycloak 2>/dev/null || true
            podman rm keycloak 2>/dev/null || true
            
            # Start with new hostname
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
              -e KC_HOSTNAME=$HOSTNAME \
              -e KC_HTTP_ENABLED=true \
              -p 8080:8080 \
              quay.io/keycloak/keycloak:latest start-dev
            
            echo "✅ Keycloak restarted with new configuration"
            echo "⏳ Waiting for Keycloak to be ready (this may take 30-60 seconds)..."
            sleep 15
        fi
    fi
fi

echo ""
echo "🔥 Firewall Configuration"
echo "=================================="
echo "To allow external access, ensure port 8080 is open:"
echo ""
echo "  Ubuntu/Debian (ufw):"
echo "    sudo ufw allow 8080/tcp"
echo ""
echo "  RHEL/CentOS (firewalld):"
echo "    sudo firewall-cmd --add-port=8080/tcp --permanent"
echo "    sudo firewall-cmd --reload"
echo ""

if [[ "$choice" == "2" ]]; then
    echo "🔗 Access URLs"
    echo "=================================="
    echo "From this machine:"
    echo "  http://localhost:8080/admin"
    echo ""
    echo "From other machines on the network:"
    echo "  http://$HOSTNAME:8080/admin"
    echo ""
    echo "📱 Mobile/Remote Testing:"
    echo "  Make sure both devices are on the same network"
    echo "  Open: http://$HOSTNAME:8080/admin"
    echo ""
fi

echo "✅ Configuration complete!"
echo ""
echo "💡 Next steps:"
echo "  1. Configure firewall (see above)"
echo "  2. Access: http://$HOSTNAME:8080/admin"
echo "  3. Login with: admin / admin"
echo "  4. Change the admin password immediately!"
