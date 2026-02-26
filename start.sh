#!/bin/bash

# Keycloak startup script using Podman/Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Starting Keycloak Identity Provider..."

# Check if podman is available, otherwise use docker
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Error: Neither podman-compose nor docker-compose found"
    echo "Please install Podman or Docker"
    exit 1
fi

echo "📦 Using: $COMPOSE_CMD"

# Start services
$COMPOSE_CMD up -d

echo ""
echo "✅ Services started successfully!"
echo ""
echo "📋 Service Status:"
$COMPOSE_CMD ps

echo ""
echo "🔗 Access Points:"
echo "   Keycloak Admin Console: https://localhost/admin"
echo "   Keycloak Health Check:  https://localhost/health/ready"
echo "   PostgreSQL:             localhost:5432"
echo ""
echo "👤 Default Credentials:"
echo "   Admin Username: admin"
echo "   Admin Password: admin"
echo ""
echo "📝 View logs with: $COMPOSE_CMD logs -f keycloak"
echo "🛑 Stop with:     $COMPOSE_CMD down"
