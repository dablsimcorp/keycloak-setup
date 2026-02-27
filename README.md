# Keycloak Identity Provider Setup

A complete, containerized deployment of Keycloak using Podman/Docker with PostgreSQL and HTTPS support.

## What is Keycloak?

[Keycloak](https://www.keycloak.org/) is an open-source identity and access management (IAM) platform that provides:

- **OpenID Connect & OAuth 2.0** - Standard authentication protocols
- **User Management** - User accounts, roles, and permissions
- **Social Login** - Integration with Google, GitHub, Facebook, etc.
- **Multi-Factor Authentication** - TOTP, WebAuthn, etc.
- **Realm Separation** - Multi-tenant support
- **User Federation** - LDAP, Active Directory integration
- **REST Admin API** - Programmatic access

Perfect for:
- Single Sign-On (SSO) across applications
- Microservices authentication
## Detailed Guides

| Guide | Purpose |
|-------|---------|
| [QUICKSTART.md](QUICKSTART.md) | Step-by-step deployment guide |
| [WINDOWS.md](WINDOWS.md) | Windows (WSL2) setup instructions |
| [NETWORK-SETUP.md](NETWORK-SETUP.md) | Configure external access |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deploy to other machines |

## What's Included

```
keycloak-setup/
├── docker-compose.yml         # Service orchestration (Keycloak + PostgreSQL + Nginx)
├── nginx/
│   ├── nginx.conf            # HTTP/HTTPS reverse proxy
│   └── ssl/                  # SSL certificates directory
├── .env.example              # Configuration template
├── install-prerequisites.sh  # Install Podman/Docker
├── generate-ssl.sh           # Generate SSL certificates
├── configure-network.sh      # Configure network access
├── start.sh                  # Start services
├── stop.sh                   # Stop services
├── status.sh                 # Check service health
└── deploy.sh                 # Automated deployment
```

## Common Tasks

### Check Service Status
```bash
podman-compose ps
./status.sh
```

### View Logs
```bash
podman-compose logs -f keycloak
```

### Stop Services
```bash
podman-compose down
```

### Access from Another Machine
```bash
# 1. Find your IP
hostname -I

# 2. Configure
./configure-network.sh

# 3. Update SSL certificate for your IP
./generate-ssl.sh

# 4. Restart
podman-compose down
podman-compose up -d

# 5. Access via: https://YOUR_IP/admin
```

## Configuration Files

### .env - Environment Settings
Main configuration file. Copy from `.env.example`:
```bash
cp .env.example .env
nano .env  # Edit as needed
```

Key variables:
- `KC_HOSTNAME` - Server IP or domain
- `KEYCLOAK_ADMIN_PASSWORD` - Admin password
- `POSTGRES_PASSWORD` - Database password

### docker-compose.yml - Services
Defines three services:
1. **keycloak** - Identity provider (Port 8080 internally)
2. **postgres** - Database (Port 5432 internally)
3. **nginx** - Reverse proxy (Port 80→443, external)

All services are containerized and isolated.

## Ports

| Port | Service | Purpose |
|------|---------|---------|
| 80 | Nginx | HTTP (redirects to HTTPS) |
| 443 | Nginx | HTTPS (Keycloak) |
| 5432 | PostgreSQL | Database (internal only) |

External access: **HTTPS only** (port 443)
Internal access: HTTP redirected to HTTPS

## Troubleshooting

### podman-compose command not found
```bash
# Install podman-compose
sudo curl -o /usr/local/bin/podman-compose \
  https://raw.githubusercontent.com/containers/podman-compose/main/podman-compose
sudo chmod +x /usr/local/bin/podman-compose
```

### Port 80/443 already in use
```bash
# Find what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Or use different ports in .env
# Update compose file to use different host ports
```

### SSL Certificate Warning
This is expected with self-signed certificates. For production:
1. Use Let's Encrypt certificates
2. Update `nginx/ssl/cert.pem` and `nginx/ssl/key.pem`
3. Or configure automatic renewal

### Keycloak not accessible
```bash
# Check container status
podman-compose logs keycloak

# Verify nginx is running
podman-compose logs nginx

# Test connectivity
curl -k https://localhost/health/ready
```

## Production Considerations

For production deployments:

1. **Use real SSL certificates** - Replace self-signed with Let's Encrypt or commercial cert
2. **Change default passwords** - Update admin and database passwords in `.env`
3. **Configure backups** - Regular PostgreSQL backups
4. **Set proper firewall rules** - Only allow HTTPS (port 443)
5. **Use strong credentials** - Generate secure random passwords
6. **Monitor logs** - Set up log aggregation
7. **Configure authentication themes** - Customize login pages
8. **Set up realms and clients** - Configure for your applications

## Next Steps

1. **Activate Admin Account** - Change default password immediately
2. **Create Realms** - Organize users and applications by realm
3. **Configure Clients** - Register OAuth 2.0 / OIDC clients
4. **Set Up Authentication** - Configure 2FA, social login, etc.
5. **Integrate Applications** - Connect services to Keycloak

## Documentation

- [Keycloak Official Docs](https://www.keycloak.org/documentation.html)
- [OIDC Authentication](https://www.keycloak.org/docs/latest/server_admin/)
- [Docker Hub - Keycloak](https://hub.docker.com/r/keycloak/keycloak)

## License

This setup is provided as-is. Keycloak is licensed under Apache License 2.0.

## Support

For issues:
- Check [Keycloak Issues](https://github.com/keycloak/keycloak/issues)
- Review logs: `podman-compose logs`
- See [QUICKSTART.md](QUICKSTART.md) for common solutions

---

**Version**: 1.0  
**Keycloak**: 26.x  
**Last Updated**: 2026-02-27
podman-compose up -d
```

## Production Deployment

For production use:

1. **Change admin password** immediately
2. **Update KC_PROXY** setting based on your reverse proxy
3. **Enable HTTPS**: Set `KC_HTTPS_ENABLED=true` and provide certs
4. **Use environment variables** for sensitive data
5. **Configure backup** for PostgreSQL data
6. **Scale database** with proper resources
7. **Use strong database passwords**

## Security Notes

⚠️ **Development Only**: The current `.env` has weak credentials suitable only for local development.

For production:
- Use strong, randomly generated passwords
- Use external secrets manager
- Enable HTTPS
- Restrict database access
- Implement regular backups
- Monitor authentication logs

## Documentation Links

- [Keycloak Official Docs](https://www.keycloak.org/documentation)
- [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/)
- [OpenID Connect Protocol](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 Specification](https://tools.ietf.org/html/rfc6749)

## Deployment to External Machines

To deploy this Keycloak setup to other servers or machines:

### Option 1: Quick Deploy from GitHub (Recommended)

```bash
# On target machine
git clone https://github.com/dablsimcorp/keycloak-setup.git
cd keycloak-setup
./deploy.sh
```

### Option 2: Manual Deployment

```bash
# Transfer project files to target machine
scp -r /home/sa/repo/idp-setup user@target-machine:~

# On target machine
cd idp-setup
./install-prerequisites.sh  # Install podman, etc.
./configure-network.sh      # Configure network
./start.sh                  # Start services
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Cloud deployment (AWS, Azure, GCP)
- Kubernetes deployment
- Multi-environment setup
- Container image export/import
- Production best practices

## Next Steps

1. ✅ Start Keycloak: `./start.sh`
2. 📝 Create a realm in the Admin Console
3. 👥 Create a user account
4. 🔑 Create an OIDC client
5. 🔗 Integrate with your application
6. 🌐 Deploy to external machines (see [DEPLOYMENT.md](DEPLOYMENT.md))

## Support

For issues or questions:
- Check Keycloak logs: `podman-compose logs keycloak`
- Consult official documentation: https://www.keycloak.org/docs
- Visit community forums: https://github.com/keycloak/keycloak/discussions
