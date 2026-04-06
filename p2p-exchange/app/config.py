"""Configuration management for the P2P Exchange application."""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration."""

    SECRET_KEY = os.environ.get("SECRET_KEY", os.urandom(32).hex())
    DEBUG = False
    TESTING = False

    # Database
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", "sqlite:///p2p_exchange.db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # TRON Network
    TRON_NETWORK = os.environ.get("TRON_NETWORK", "mainnet")
    TRONGRID_API_URL = os.environ.get(
        "TRONGRID_API_URL", "https://api.trongrid.io"
    )
    TRONGRID_API_KEY = os.environ.get("TRONGRID_API_KEY", "")
    TRON_RPC_ENDPOINTS = [
        ep.strip()
        for ep in os.environ.get(
            "TRON_RPC_ENDPOINTS", "https://api.trongrid.io"
        ).split(",")
        if ep.strip()
    ]
    USDT_CONTRACT_ADDRESS = os.environ.get(
        "USDT_CONTRACT_ADDRESS", "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
    )

    # Escrow
    ESCROW_TIMEOUT_HOURS = int(os.environ.get("ESCROW_TIMEOUT_HOURS", 24))
    ESCROW_CONFIRMATION_BLOCKS = int(
        os.environ.get("ESCROW_CONFIRMATION_BLOCKS", 20)
    )

    # Rate Limiting
    RATE_LIMIT_DEFAULT = os.environ.get("RATE_LIMIT_DEFAULT", "100/hour")
    RATE_LIMIT_TRADE = os.environ.get("RATE_LIMIT_TRADE", "20/hour")

    # Notifications
    SMTP_HOST = os.environ.get("SMTP_HOST", "")
    SMTP_PORT = int(os.environ.get("SMTP_PORT", 587))
    SMTP_USER = os.environ.get("SMTP_USER", "")
    SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
    SMTP_FROM = os.environ.get("SMTP_FROM", "")
    NOSTR_RELAY_URL = os.environ.get("NOSTR_RELAY_URL", "")
    SESSION_BOT_API_URL = os.environ.get("SESSION_BOT_API_URL", "")

    # Tor
    TOR_ENABLED = os.environ.get("TOR_ENABLED", "false").lower() == "true"
    ONION_ADDRESS = os.environ.get("ONION_ADDRESS", "")

    # Logging
    LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
    LOG_FILE = os.environ.get("LOG_FILE", "p2p_exchange.log")


class DevelopmentConfig(Config):
    """Development configuration."""

    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", "sqlite:///p2p_exchange_dev.db"
    )


class TestingConfig(Config):
    """Testing configuration."""

    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    WTF_CSRF_ENABLED = False


class ProductionConfig(Config):
    """Production configuration."""

    pass


config_by_name = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}
