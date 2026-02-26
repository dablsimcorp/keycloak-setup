# Keycloak Deployment Script for Windows PowerShell
# Alternative to deploy.sh for Windows users

Write-Host ""
Write-Host "🚀 Keycloak Quick Deployment for Windows" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop from:" -ForegroundColor Yellow
    Write-Host "https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✓ Docker found" -ForegroundColor Green

# Check if docker-compose exists
$composeCmd = "docker-compose"
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    # Try new docker compose syntax
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $composeCmd = "docker compose"
        Write-Host "✓ Using 'docker compose' command" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Docker Compose found" -ForegroundColor Green
}

Write-Host ""
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Create .env configuration file" -ForegroundColor Yellow
Write-Host "  2. Start Keycloak and PostgreSQL containers" -ForegroundColor Yellow
Write-Host "  3. Configure network access" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue with deployment? [Y/n]"
if ($confirm -and $confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Step 1/3: Configuration" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Create .env from .env.example if it doesn't exist
if (!(Test-Path .env)) {
    if (Test-Path .env.example) {
        Copy-Item .env.example .env
        Write-Host "✓ Created .env from .env.example" -ForegroundColor Green
    } else {
        # Create default .env
        @"
# Keycloak Configuration
KC_HOSTNAME=localhost
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
"@ | Out-File -FilePath .env -Encoding UTF8
        Write-Host "✓ Created default .env file" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Using existing .env file" -ForegroundColor Green
}

# Detect Windows IP
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "📍 Detected Windows IP: $ipAddress" -ForegroundColor Cyan
Write-Host ""
Write-Host "Choose access mode:" -ForegroundColor Yellow
Write-Host "  1) Local only (localhost) - accessible only from this computer" -ForegroundColor Yellow
Write-Host "  2) Network access ($ipAddress) - accessible from other devices" -ForegroundColor Yellow
Write-Host "  3) Custom hostname/domain" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Enter choice [1-3]"

switch ($choice) {
    "1" {
        $hostname = "localhost"
        Write-Host "✓ Configured for local access only" -ForegroundColor Green
    }
    "2" {
        $hostname = $ipAddress
        Write-Host "✓ Configured for network access at $ipAddress" -ForegroundColor Green
    }
    "3" {
        $hostname = Read-Host "Enter hostname or domain"
        Write-Host "✓ Configured for custom hostname: $hostname" -ForegroundColor Green
    }
    default {
        $hostname = "localhost"
        Write-Host "✓ Using default: localhost" -ForegroundColor Green
    }
}

# Update KC_HOSTNAME in .env
$envContent = Get-Content .env
$envContent = $envContent -replace "^KC_HOSTNAME=.*", "KC_HOSTNAME=$hostname"
$envContent | Out-File -FilePath .env -Encoding UTF8
Write-Host "✓ Updated KC_HOSTNAME to $hostname" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Step 2/3: Starting Services" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Stop existing containers if any
Write-Host "Stopping any existing containers..." -ForegroundColor Yellow
Invoke-Expression "$composeCmd down 2>$null" | Out-Null

# Pull images
Write-Host "Pulling container images..." -ForegroundColor Yellow
Invoke-Expression "$composeCmd pull"

# Start services
Write-Host ""
Write-Host "Starting Keycloak and PostgreSQL..." -ForegroundColor Yellow
Invoke-Expression "$composeCmd up -d"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Services started successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Step 3/3: Waiting for Initialization" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Waiting for Keycloak to initialize (30-60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Show status
Write-Host ""
Write-Host "📊 Service Status:" -ForegroundColor Cyan
Invoke-Expression "$composeCmd ps"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 Access Points:" -ForegroundColor Cyan
if ($hostname -eq "localhost") {
    Write-Host "   Admin Console: http://localhost:8080/admin" -ForegroundColor White
} else {
    Write-Host "   From this computer:  http://localhost:8080/admin" -ForegroundColor White
    Write-Host "   From other devices:  http://${hostname}:8080/admin" -ForegroundColor White
}

Write-Host ""
Write-Host "👤 Default Credentials:" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: admin" -ForegroundColor White

Write-Host ""
Write-Host "⚠️  Important Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 30-60 seconds for Keycloak to fully start" -ForegroundColor White
Write-Host "   2. Access the admin console (URLs above)" -ForegroundColor White
Write-Host "   3. Login and CHANGE the admin password immediately!" -ForegroundColor White

if ($hostname -ne "localhost") {
    Write-Host "   4. Configure Windows Firewall:" -ForegroundColor White
    Write-Host "      New-NetFirewallRule -DisplayName 'Keycloak' -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   - Windows Guide:  WINDOWS.md" -ForegroundColor White
Write-Host "   - Quick Start:    QUICKSTART.md" -ForegroundColor White
Write-Host "   - Network Setup:  NETWORK-SETUP.md" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Useful Commands:" -ForegroundColor Cyan
Write-Host "   Check status:  $composeCmd ps" -ForegroundColor Gray
Write-Host "   View logs:     $composeCmd logs -f keycloak" -ForegroundColor Gray
Write-Host "   Stop:          $composeCmd down" -ForegroundColor Gray
Write-Host "   Restart:       $composeCmd restart keycloak" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 Happy authenticating!" -ForegroundColor Cyan
Write-Host ""
