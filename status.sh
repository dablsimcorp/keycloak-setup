#!/bin/bash

# Check Keycloak services status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if podman is available, otherwise use docker
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Error: Neither podman-compose nor docker-compose found"
    exit 1
fi

echo "📊 Keycloak Services Status"
echo "============================"
echo ""

# Show container status
echo "🐳 Container Status:"
$COMPOSE_CMD ps

echo ""
echo "🏥 Health Checks:"
echo ""

# Check Keycloak health
if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
    echo "✅ Keycloak (http://localhost:8080): HEALTHY"
else
    echo "❌ Keycloak (http://localhost:8080): UNAVAILABLE"
fi

# Check PostgreSQL
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/localhost/5432" 2>/dev/null; then
    echo "✅ PostgreSQL (localhost:5432): HEALTHY"
else
    echo "❌ PostgreSQL (localhost:5432): UNAVAILABLE"
fi

echo ""
echo "📝 Full Container Logs:"
echo "  Keycloak:  $COMPOSE_CMD logs keycloak"
echo "  PostgreSQL: $COMPOSE_CMD logs postgres"
