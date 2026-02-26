#!/bin/bash

# Package Keycloak setup for deployment to external machines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_FILE="keycloak-setup-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "📦 Packaging Keycloak Setup for External Deployment"
echo "===================================================="
echo ""

# Files to include in the package
FILES=(
    "docker-compose.yml"
    "docker-compose.prod.yml"
    "docker-compose.nginx.yml"
    ".env.example"
    "*.sh"
    "*.md"
    "nginx/"
    ".gitignore"
)

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/keycloak-setup"
mkdir -p "$PACKAGE_DIR"

echo "📋 Including files:"
echo ""

# Copy configuration files
for pattern in "${FILES[@]}"; do
    if ls $pattern 1> /dev/null 2>&1; then
        cp -r $pattern "$PACKAGE_DIR/" 2>/dev/null || true
        echo "  ✓ $pattern"
    fi
done

# Create .env.example if .env exists but .env.example doesn't
if [ -f ".env" ] && [ ! -f "$PACKAGE_DIR/.env.example" ]; then
    cp .env "$PACKAGE_DIR/.env.example"
    # Remove sensitive values
    sed -i 's/KEYCLOAK_ADMIN_PASSWORD=.*/KEYCLOAK_ADMIN_PASSWORD=changeme/' "$PACKAGE_DIR/.env.example" 2>/dev/null || true
    sed -i 's/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=changeme/' "$PACKAGE_DIR/.env.example" 2>/dev/null || true
    echo "  ✓ .env.example (sanitized)"
fi

# Copy .env as .env.example if it doesn't exist
if [ ! -f "$PACKAGE_DIR/.env.example" ]; then
    cp "$PACKAGE_DIR/.env" "$PACKAGE_DIR/.env.example" 2>/dev/null || true
fi

# Make scripts executable
chmod +x "$PACKAGE_DIR"/*.sh 2>/dev/null || true

# Create a deployment README
cat > "$PACKAGE_DIR/DEPLOY-INSTRUCTIONS.txt" << 'EOF'
╔════════════════════════════════════════════════════════════╗
║           KEYCLOAK DEPLOYMENT INSTRUCTIONS                 ║
╚════════════════════════════════════════════════════════════╝

Quick Start on External Machine:
─────────────────────────────────

1. EXTRACT THIS PACKAGE:
   tar -xzf keycloak-setup-*.tar.gz
   cd keycloak-setup

2. INSTALL PREREQUISITES:
   ./install-prerequisites.sh

3. QUICK DEPLOY (Automated):
   ./deploy.sh

   OR Manual Steps:
   a) Copy .env.example to .env:
      cp .env.example .env
   
   b) Edit .env with your settings:
      vim .env
      # Update KC_HOSTNAME, passwords, etc.
   
   c) Configure network:
      ./configure-network.sh
   
   d) Start services:
      ./start.sh

4. ACCESS KEYCLOAK:
   http://localhost:8080/admin
   Username: admin
   Password: admin (CHANGE THIS!)

5. CONFIGURE FIREWALL (if needed):
   sudo ufw allow 8080/tcp

─────────────────────────────────────────────────────────────

Prerequisites:
• Podman 4.0+ or Docker 20.0+
• 2+ CPU cores
• 4GB+ RAM
• 20GB+ disk space

Supported OS:
• Ubuntu 20.04/22.04/24.04
• Debian 11/12
• RHEL 8/9
• Rocky Linux 8/9
• Fedora 38+

Documentation:
• README.md - Complete overview
• QUICKSTART.md - Quick setup guide
• NETWORK-SETUP.md - Network configuration
• DEPLOYMENT.md - Deployment scenarios

Support:
Check the included documentation files for detailed
instructions and troubleshooting guides.

Security Notes:
⚠️  CHANGE DEFAULT PASSWORDS IMMEDIATELY!
⚠️  Use HTTPS for production deployments
⚠️  Configure firewall properly
⚠️  Keep software updated

For production deployment with HTTPS:
1. Run: ./generate-ssl.sh
2. Use: docker-compose -f docker-compose.nginx.yml up -d

EOF

echo ""
echo "📝 Creating deployment instructions..."

# Create the tarball
echo ""
echo "🗜️  Creating package..."
cd "$TEMP_DIR"
tar -czf "$SCRIPT_DIR/$OUTPUT_FILE" keycloak-setup/

# Cleanup
rm -rf "$TEMP_DIR"

# Get file size
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Package Created Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Package: $OUTPUT_FILE"
echo "📊 Size:    $FILE_SIZE"
echo "📂 Location: $SCRIPT_DIR/$OUTPUT_FILE"
echo ""
echo "🚀 Deploy to External Machine:"
echo ""
echo "1. Transfer the package:"
echo "   scp $OUTPUT_FILE user@remote-machine:~"
echo ""
echo "2. On the remote machine:"
echo "   tar -xzf $OUTPUT_FILE"
echo "   cd keycloak-setup"
echo "   ./deploy.sh"
echo ""
echo "3. Or for manual control:"
echo "   ./install-prerequisites.sh"
echo "   ./configure-network.sh"
echo "   ./start.sh"
echo ""
echo "📝 Deployment instructions are included in the package:"
echo "   DEPLOY-INSTRUCTIONS.txt"
echo ""
