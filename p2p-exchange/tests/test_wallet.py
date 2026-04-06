"""Tests for TRON wallet operations."""

from app.services.tron import TronService


class TestTronAddressGeneration:
    """Test TRON address and keypair generation."""

    def test_generate_keypair(self):
        """Test that keypair generation produces valid data."""
        kp = TronService.generate_keypair()

        assert "private_key" in kp
        assert "public_key" in kp
        assert "address" in kp
        assert len(kp["private_key"]) == 64  # 32 bytes hex
        assert kp["address"].startswith("T")

    def test_address_from_private_key(self):
        """Test deriving address from private key is consistent."""
        kp = TronService.generate_keypair()
        derived_address = TronService.address_from_private_key(
            kp["private_key"]
        )

        assert derived_address == kp["address"]

    def test_validate_valid_address(self):
        """Test validation of a valid TRON address."""
        kp = TronService.generate_keypair()
        assert TronService.validate_address(kp["address"]) is True

    def test_validate_invalid_address(self):
        """Test validation of invalid addresses."""
        assert TronService.validate_address("") is False
        assert TronService.validate_address("invalid") is False
        assert TronService.validate_address("T" * 100) is False

    def test_unique_addresses(self):
        """Test that multiple keypairs produce different addresses."""
        kp1 = TronService.generate_keypair()
        kp2 = TronService.generate_keypair()

        assert kp1["address"] != kp2["address"]
        assert kp1["private_key"] != kp2["private_key"]

    def test_address_length(self):
        """Test that generated addresses have proper length."""
        kp = TronService.generate_keypair()
        # TRON base58check addresses are typically 34 chars
        assert 30 <= len(kp["address"]) <= 36


class TestTronServiceInit:
    """Test TronService initialization."""

    def test_default_init(self):
        """Test default initialization values."""
        svc = TronService()

        assert svc.api_url == "https://api.trongrid.io"
        assert (
            svc.usdt_contract
            == "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        )

    def test_init_with_app(self, app):
        """Test initialization with Flask app config."""
        svc = TronService(app)

        assert svc.api_url == app.config["TRONGRID_API_URL"]
