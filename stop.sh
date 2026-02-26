#!/bin/bash

# Keycloak shutdown script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🛑 Stopping Keycloak Identity Provider..."

# Check if podman is available, otherwise use docker
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Error: Neither podman-compose nor docker-compose found"
    exit 1
fi

# Stop services
$COMPOSE_CMD down

echo "✅ Services stopped"
echo ""
echo "💾 Data persisted in:"
echo "   - PostgreSQL volume: keycloak-setup_postgres_data"
echo ""
echo "To remove all data: $COMPOSE_CMD down -v"
