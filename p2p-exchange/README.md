# P2P Exchange — Non-Custodial USDT-TRC20 Trading Platform

A no-KYC, non-custodial peer-to-peer exchange for USDT-TRC20 trading. Users create buy/sell offers, match with counterparties, and complete trades using on-chain escrow — all without registration, identity verification, or centralized custody of funds.

## Features

- **No-KYC / No-Registration**: Trade anonymously with session-based pseudonymous identities. Optional 12-word BIP39 mnemonic for persistent identity recovery.
- **Non-Custodial Escrow**: Sellers fund on-chain escrow addresses. The platform never holds private keys or custodies funds.
- **USDT-TRC20 Integration**: Full TRON wallet support — address generation, balance checking, transaction building, and confirmation monitoring via TronGrid API.
- **E2E Encrypted Chat**: Trade communications encrypted with X25519 + XSalsa20-Poly1305 (NaCl box). Server stores only ciphertext.
- **Reputation System**: Trust scores based on trade completion rate, response time, volume, and dispute rate.
- **Dispute Resolution**: Arbitration system for disputed trades with encrypted evidence review.
- **Tor-Friendly**: No external CDNs, no analytics, no tracking. Fully functional as a `.onion` hidden service.
- **BitID Authentication**: Passwordless authentication via cryptographic challenge-response.
- **Multi-Account Support**: Trading accounts, watch-only addresses, and hardware wallet signing.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Python 3.12, Flask 3.1 |
| Frontend | HTML5, CSS3, Vanilla JavaScript |
| Database | SQLite (dev) / PostgreSQL (prod) |
| WebSocket | Flask-SocketIO + gevent |
| Encryption | PyNaCl (libsodium), Web Crypto API |
| Blockchain | TRON/TRC20 via TronGrid API |
| Web Server | Apache2 reverse proxy to Gunicorn |
| Tor | Hidden service on port 80 |
| Deployment | Docker + docker-compose |

## Quick Start

### Development

```bash
# Clone and enter directory
cd p2p-exchange

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run development server
python -m app.main
```

Open http://localhost:5000 in your browser.

### Automated Setup

```bash
# Development mode
./setup.sh --dev

# Production mode (requires root)
sudo ./setup.sh --prod

# Production + Tor hidden service
sudo ./setup.sh --prod --tor
```

### Docker

```bash
cd deploy

# Start all services (app + PostgreSQL + Tor)
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

## Project Structure

```
p2p-exchange/
├── app/
│   ├── __init__.py
│   ├── main.py                  # Application entry point & factory
│   ├── config.py                # Configuration management
│   ├── models/                  # Database models
│   │   ├── user.py              # Pseudonymous user identity
│   │   ├── offer.py             # Buy/sell offer listings
│   │   ├── trade.py             # Trade lifecycle management
│   │   └── message.py           # E2E encrypted chat messages
│   ├── routes/                  # API endpoints
│   │   ├── auth.py              # Session, mnemonic, BitID auth
│   │   ├── offers.py            # CRUD for trading offers
│   │   ├── trades.py            # Trade lifecycle & escrow
│   │   ├── chat.py              # Encrypted messaging
│   │   └── wallet.py            # TRON wallet operations
│   ├── services/                # Business logic
│   │   ├── tron.py              # TRON/TRC20 blockchain integration
│   │   ├── escrow.py            # Non-custodial escrow management
│   │   ├── encryption.py        # E2E encryption (NaCl box)
│   │   ├── reputation.py        # Trust score calculation
│   │   └── notifications.py     # Multi-channel notifications
│   ├── static/                  # Frontend assets
│   │   ├── css/style.css        # Dark theme responsive stylesheet
│   │   └── js/
│   │       ├── app.js           # Core API client & session management
│   │       └── encryption.js    # Client-side encryption module
│   └── templates/               # Jinja2 HTML templates
│       ├── base.html            # Base layout with navigation
│       ├── index.html           # Landing page with identity management
│       ├── offers.html          # Offer listing, creation & trading
│       ├── trade.html           # Trade lifecycle management
│       └── chat.html            # E2E encrypted chat interface
├── deploy/
│   ├── apache.conf              # Apache virtual host config
│   ├── torrc                    # Tor hidden service config
│   ├── Dockerfile               # Container image
│   └── docker-compose.yml       # Full stack deployment
├── tests/                       # Test suite (40 tests)
│   ├── conftest.py              # Test fixtures
│   ├── test_auth.py             # Authentication tests
│   ├── test_offers.py           # Offer CRUD tests
│   ├── test_encryption.py       # E2E encryption tests
│   ├── test_wallet.py           # TRON wallet tests
│   └── test_reputation.py       # Reputation system tests
├── setup.sh                     # Automated setup script
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment variable template
└── README.md
```

## API Reference

### Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/session` | POST | Create anonymous session |
| `/api/auth/session/verify` | POST | Verify session token |
| `/api/auth/mnemonic/generate` | POST | Generate 12-word mnemonic |
| `/api/auth/mnemonic/restore` | POST | Restore identity from mnemonic |
| `/api/auth/bitid/challenge` | GET | Get BitID challenge |
| `/api/auth/bitid/verify` | POST | Verify BitID response |

### Offers

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/offers` | GET | No | List/filter offers |
| `/api/offers` | POST | Yes | Create offer |
| `/api/offers/<id>` | GET | No | Get offer details |
| `/api/offers/<id>` | PUT | Yes | Update own offer |
| `/api/offers/<id>` | DELETE | Yes | Close own offer |
| `/api/offers/my` | GET | Yes | List own offers |

### Trades

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/trades` | POST | Yes | Initiate trade |
| `/api/trades/<id>` | GET | Yes | Get trade details |
| `/api/trades/<id>/escrow/verify` | POST | Yes | Verify escrow funding |
| `/api/trades/<id>/fiat-sent` | POST | Yes | Confirm fiat sent (buyer) |
| `/api/trades/<id>/fiat-received` | POST | Yes | Confirm fiat received (seller) |
| `/api/trades/<id>/release` | POST | Yes | Release escrow (seller) |
| `/api/trades/<id>/dispute` | POST | Yes | Open dispute |
| `/api/trades/<id>/resolve` | POST | Yes | Resolve dispute (arbitrator) |
| `/api/trades/<id>/cancel` | POST | Yes | Cancel trade |
| `/api/trades/my` | GET | Yes | List own trades |

### Chat

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/chat/<trade_id>/messages` | GET | Yes | Get encrypted messages |
| `/api/chat/<trade_id>/messages` | POST | Yes | Send encrypted message |
| `/api/chat/<trade_id>/pubkey` | POST | Yes | Exchange chat public key |

### Wallet

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/wallet/generate` | POST | No | Generate new TRON wallet |
| `/api/wallet/balance/<addr>` | GET | No | Get TRX/USDT balances |
| `/api/wallet/validate/<addr>` | GET | No | Validate TRON address |
| `/api/wallet/send` | POST | Yes | Build/send USDT transfer |
| `/api/wallet/tx/<id>` | GET | No | Get transaction info |
| `/api/wallet/tx/<id>/confirm` | GET | No | Check confirmations |

## Trade Flow

```
1. Seller creates offer (amount, price, payment methods)
2. Buyer initiates trade → Escrow address generated
3. Seller sends USDT-TRC20 to escrow address
4. Platform verifies on-chain funding (20+ confirmations)
5. Buyer sends fiat payment to seller (off-chain)
6. Buyer clicks "Fiat Sent" in the UI
7. Seller verifies fiat receipt
8. Seller clicks "Fiat Received" → "Release Escrow"
9. USDT released to buyer's wallet address
10. Both parties' reputation scores updated
```

If disputed at any step, an arbitrator reviews encrypted evidence and directs fund release.

## Security

- **Transport**: TLS 1.3 (clearnet), Tor E2E encryption (hidden service)
- **Authentication**: HMAC-signed session tokens, BitID, mnemonic-derived keypairs
- **Chat Encryption**: X25519 key exchange + XSalsa20-Poly1305 (NaCl box)
- **Headers**: Strict CSP, X-Frame-Options DENY, HSTS, no-referrer
- **Rate Limiting**: Per-IP limits on all API endpoints
- **CSRF**: Full protection with WTF-CSRF (HTML forms) + token auth (API)
- **No External Resources**: All assets served locally (Tor-compatible)
- **Secrets**: All credentials in environment variables, never hardcoded

## Configuration

Copy `.env.example` to `.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Flask secret key (64 hex chars) | Random |
| `DATABASE_URL` | Database connection string | SQLite |
| `TRONGRID_API_URL` | TronGrid API endpoint | mainnet |
| `TRONGRID_API_KEY` | TronGrid API key | (empty) |
| `USDT_CONTRACT_ADDRESS` | USDT TRC20 contract | mainnet |
| `ESCROW_TIMEOUT_HOURS` | Escrow expiry time | 24 |
| `TOR_ENABLED` | Enable Tor mode | false |
| `RATE_LIMIT_DEFAULT` | Default rate limit | 100/hour |

## Testing

```bash
# Run all tests
python -m pytest tests/ -v

# With coverage
python -m pytest tests/ --cov=app --cov-report=term-missing

# Specific test file
python -m pytest tests/test_encryption.py -v
```

## Deployment

### Apache Configuration

The included `deploy/apache.conf` configures:
- Reverse proxy to Gunicorn on port 5000
- Static file serving with caching
- WebSocket proxy for real-time chat
- Security headers (CSP, HSTS, X-Frame-Options)

```bash
sudo cp deploy/apache.conf /etc/apache2/sites-available/p2p-exchange.conf
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers expires
sudo a2ensite p2p-exchange.conf
sudo systemctl reload apache2
```

### Tor Hidden Service

```bash
# Install Tor
sudo apt install tor

# Add hidden service config
sudo cat deploy/torrc >> /etc/tor/torrc
sudo systemctl restart tor

# Get your .onion address
sudo cat /var/lib/tor/p2p-exchange/hostname
```

### Production Gunicorn

```bash
gunicorn \
  --worker-class geventwebsocket.gunicorn.workers.GeventWebSocketWorker \
  --workers 4 \
  --bind 0.0.0.0:5000 \
  --timeout 120 \
  'app.main:create_app()'
```

## License

This project is provided as-is for educational and research purposes.
