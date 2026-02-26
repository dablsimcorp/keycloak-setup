#!/bin/bash

# Generate self-signed SSL certificates for Keycloak (development/testing only)
# For production, use Let's Encrypt or proper CA-signed certificates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/nginx/ssl"

echo "🔐 Generate SSL Certificates for Keycloak"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will generate SELF-SIGNED certificates"
echo "    These are suitable for DEVELOPMENT/TESTING ONLY"
echo "    For production, use Let's Encrypt or proper CA certificates"
echo ""

read -p "Continue? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Get hostname
read -p "Enter hostname (e.g., keycloak.local or IP address): " HOSTNAME
if [ -z "$HOSTNAME" ]; then
    echo "❌ Hostname is required"
    exit 1
fi

echo ""
echo "📝 Generating SSL certificate for: $HOSTNAME"
echo ""

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate private key
openssl genrsa -out "$SSL_DIR/key.pem" 2048 2>/dev/null

# Generate certificate signing request and self-signed certificate
openssl req -new -x509 -key "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem" -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$HOSTNAME" \
    -addext "subjectAltName=DNS:$HOSTNAME,DNS:localhost,IP:127.0.0.1" 2>/dev/null

# Set appropriate permissions
chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo "✅ SSL certificates generated successfully!"
echo ""
echo "📂 Certificate files:"
echo "  Certificate: $SSL_DIR/cert.pem"
echo "  Private Key: $SSL_DIR/key.pem"
echo ""
echo "📋 Certificate details:"
openssl x509 -in "$SSL_DIR/cert.pem" -noout -subject -dates
echo ""
echo "⚙️  Next steps:"
echo "  1. Update nginx/nginx.conf to enable HTTPS (uncomment HTTPS server block)"
echo "  2. Update KC_HOSTNAME in .env to use your hostname: $HOSTNAME"
echo "  3. Start with nginx: podman-compose -f docker-compose.nginx.yml up -d"
echo "  4. Access: https://$HOSTNAME (you'll see a browser warning - this is normal for self-signed certs)"
echo ""
echo "🔒 Browser Security Warning:"
echo "  Your browser will show a security warning. This is expected for self-signed certificates."
echo "  You can safely proceed/accept the certificate for testing purposes."
echo ""
echo "🌐 For production with Let's Encrypt:"
echo "  Use certbot to get free SSL certificates:"
echo "    sudo certbot certonly --standalone -d $HOSTNAME"
echo "    Then copy cert.pem and privkey.pem to nginx/ssl/"
