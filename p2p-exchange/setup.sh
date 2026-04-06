#!/usr/bin/env bash
# P2P Exchange - Automated Setup Script
#
# This script installs dependencies, configures Apache, Tor,
# initializes the database, and generates encryption keys.
#
# Usage: sudo ./setup.sh [--dev|--prod|--tor]
#
# Options:
#   --dev   Development mode (SQLite, debug enabled)
#   --prod  Production mode (PostgreSQL, Apache)
#   --tor   Enable Tor hidden service

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
MODE="dev"
ENABLE_TOR=false

for arg in "$@"; do
    case $arg in
        --dev)  MODE="dev" ;;
        --prod) MODE="prod" ;;
        --tor)  ENABLE_TOR=true ;;
        *)      warn "Unknown argument: $arg" ;;
    esac
done

log "P2P Exchange Setup - Mode: ${MODE}"

# Check if running as root for production
if [ "$MODE" = "prod" ] && [ "$(id -u)" -ne 0 ]; then
    error "Production setup requires root privileges. Run with sudo."
fi

# 1. Install system dependencies
log "Installing system dependencies..."
if command -v apt-get &> /dev/null; then
    if [ "$MODE" = "prod" ]; then
        apt-get update
        apt-get install -y python3 python3-pip python3-venv \
            apache2 libapache2-mod-proxy-html \
            postgresql postgresql-contrib \
            libffi-dev gcc
    fi
elif command -v yum &> /dev/null; then
    if [ "$MODE" = "prod" ]; then
        yum install -y python3 python3-pip \
            httpd postgresql-server \
            libffi-devel gcc
    fi
fi

# 2. Set up Python virtual environment
log "Setting up Python virtual environment..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

python3 -m venv venv
source venv/bin/activate

# 3. Install Python dependencies
log "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# 4. Generate secret key
log "Generating secret key..."
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

# 5. Create .env file
if [ ! -f .env ]; then
    log "Creating .env configuration file..."
    cp .env.example .env
    sed -i "s/change-me-to-a-random-64-char-hex-string/${SECRET_KEY}/" .env

    if [ "$MODE" = "prod" ]; then
        sed -i 's/FLASK_ENV=production/FLASK_ENV=production/' .env
        sed -i 's|DATABASE_URL=sqlite:///p2p_exchange.db|DATABASE_URL=postgresql://p2puser:changeme@localhost:5432/p2p_exchange|' .env
        sed -i 's/DEBUG=false/DEBUG=false/' .env
    else
        sed -i 's/FLASK_ENV=production/FLASK_ENV=development/' .env
        sed -i 's/DEBUG=false/DEBUG=true/' .env
    fi

    if [ "$ENABLE_TOR" = true ]; then
        sed -i 's/TOR_ENABLED=false/TOR_ENABLED=true/' .env
    fi
else
    warn ".env file already exists, skipping..."
fi

# 6. Initialize database
log "Initializing database..."
if [ "$MODE" = "prod" ]; then
    # Set up PostgreSQL
    if command -v pg_isready &> /dev/null; then
        sudo -u postgres psql -c "CREATE USER p2puser WITH PASSWORD 'changeme';" 2>/dev/null || true
        sudo -u postgres psql -c "CREATE DATABASE p2p_exchange OWNER p2puser;" 2>/dev/null || true
        log "PostgreSQL database created"
    fi
fi

# Create tables
FLASK_ENV=${MODE} python3 -c "
from app.main import create_app, db
app = create_app('${MODE}' if '${MODE}' != 'prod' else 'production')
with app.app_context():
    db.create_all()
    print('Database tables created successfully')
"

# 7. Configure Apache (production only)
if [ "$MODE" = "prod" ]; then
    log "Configuring Apache..."

    # Enable required modules
    a2enmod proxy proxy_http proxy_wstunnel rewrite headers expires 2>/dev/null || true

    # Copy configuration
    cp deploy/apache.conf /etc/apache2/sites-available/p2p-exchange.conf
    a2ensite p2p-exchange.conf 2>/dev/null || true
    a2dissite 000-default.conf 2>/dev/null || true

    # Test and reload Apache
    apache2ctl configtest
    systemctl reload apache2

    log "Apache configured and reloaded"
fi

# 8. Configure Tor (if enabled)
if [ "$ENABLE_TOR" = true ]; then
    log "Configuring Tor hidden service..."

    if ! command -v tor &> /dev/null; then
        apt-get install -y tor 2>/dev/null || yum install -y tor 2>/dev/null
    fi

    # Append hidden service config to torrc
    if ! grep -q "p2p-exchange" /etc/tor/torrc 2>/dev/null; then
        cat deploy/torrc >> /etc/tor/torrc
    fi

    # Create hidden service directory
    mkdir -p /var/lib/tor/p2p-exchange
    chown debian-tor:debian-tor /var/lib/tor/p2p-exchange 2>/dev/null || true
    chmod 700 /var/lib/tor/p2p-exchange

    # Restart Tor
    systemctl restart tor 2>/dev/null || service tor restart 2>/dev/null

    # Wait for onion address
    sleep 3
    if [ -f /var/lib/tor/p2p-exchange/hostname ]; then
        ONION_ADDR=$(cat /var/lib/tor/p2p-exchange/hostname)
        log "Tor hidden service address: ${ONION_ADDR}"
        sed -i "s/ONION_ADDRESS=/ONION_ADDRESS=${ONION_ADDR}/" .env
    else
        warn "Tor is starting... Check /var/lib/tor/p2p-exchange/hostname shortly"
    fi
fi

# 9. Summary
echo ""
echo "============================================"
echo "  P2P Exchange Setup Complete!"
echo "============================================"
echo ""
log "Mode: ${MODE}"
log "Secret key generated and saved to .env"

if [ "$MODE" = "dev" ]; then
    echo ""
    log "To start the development server:"
    echo "  cd ${SCRIPT_DIR}"
    echo "  source venv/bin/activate"
    echo "  python -m app.main"
    echo ""
    echo "  Open http://localhost:5000 in your browser"
elif [ "$MODE" = "prod" ]; then
    echo ""
    log "To start the production server:"
    echo "  cd ${SCRIPT_DIR}"
    echo "  source venv/bin/activate"
    echo "  gunicorn --worker-class geventwebsocket.gunicorn.workers.GeventWebSocketWorker \\"
    echo "    --workers 4 --bind 0.0.0.0:5000 'app.main:create_app()'"
    echo ""
    echo "  Apache is configured to proxy requests on port 80"
fi

if [ "$ENABLE_TOR" = true ]; then
    echo ""
    log "Tor hidden service is configured"
    echo "  Check: sudo cat /var/lib/tor/p2p-exchange/hostname"
fi

echo ""
log "Documentation: See README.md for full details"
