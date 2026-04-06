"""Tests for the encryption service."""

from app.services.encryption import EncryptionService


class TestEncryption:
    """Test E2E encryption operations."""

    def test_generate_keypair(self):
        """Test keypair generation."""
        keypair = EncryptionService.generate_keypair()

        assert "private_key" in keypair
        assert "public_key" in keypair
        assert len(keypair["private_key"]) > 0
        assert len(keypair["public_key"]) > 0

    def test_encrypt_decrypt_roundtrip(self):
        """Test that encrypt then decrypt returns original message."""
        sender = EncryptionService.generate_keypair()
        recipient = EncryptionService.generate_keypair()

        plaintext = "Hello, this is a secret trade message!"

        # Encrypt
        encrypted = EncryptionService.encrypt_message(
            plaintext,
            sender["private_key"],
            recipient["public_key"],
        )

        assert "ciphertext" in encrypted
        assert "nonce" in encrypted
        assert encrypted["ciphertext"] != plaintext

        # Decrypt
        decrypted = EncryptionService.decrypt_message(
            encrypted["ciphertext"],
            encrypted["nonce"],
            recipient["private_key"],
            sender["public_key"],
        )

        assert decrypted == plaintext

    def test_different_keypairs_produce_different_ciphertext(self):
        """Test that same message encrypted with different keys differs."""
        sender1 = EncryptionService.generate_keypair()
        sender2 = EncryptionService.generate_keypair()
        recipient = EncryptionService.generate_keypair()

        plaintext = "Same message"

        enc1 = EncryptionService.encrypt_message(
            plaintext,
            sender1["private_key"],
            recipient["public_key"],
        )
        enc2 = EncryptionService.encrypt_message(
            plaintext,
            sender2["private_key"],
            recipient["public_key"],
        )

        # Ciphertexts should differ
        assert enc1["ciphertext"] != enc2["ciphertext"]

    def test_wrong_key_fails_decrypt(self):
        """Test that decryption with wrong key fails."""
        sender = EncryptionService.generate_keypair()
        recipient = EncryptionService.generate_keypair()
        wrong_key = EncryptionService.generate_keypair()

        plaintext = "Secret message"

        encrypted = EncryptionService.encrypt_message(
            plaintext,
            sender["private_key"],
            recipient["public_key"],
        )

        try:
            EncryptionService.decrypt_message(
                encrypted["ciphertext"],
                encrypted["nonce"],
                wrong_key["private_key"],
                sender["public_key"],
            )
            assert False, "Should have raised ValueError"
        except ValueError:
            pass  # Expected

    def test_ephemeral_keypair_is_unique(self):
        """Test that ephemeral keypairs are unique each time."""
        kp1 = EncryptionService.generate_ephemeral_keypair()
        kp2 = EncryptionService.generate_ephemeral_keypair()

        assert kp1["private_key"] != kp2["private_key"]
        assert kp1["public_key"] != kp2["public_key"]

    def test_unicode_message(self):
        """Test encryption of unicode messages."""
        sender = EncryptionService.generate_keypair()
        recipient = EncryptionService.generate_keypair()

        plaintext = "Hello 世界! 🎉 Привет мир!"

        encrypted = EncryptionService.encrypt_message(
            plaintext,
            sender["private_key"],
            recipient["public_key"],
        )

        decrypted = EncryptionService.decrypt_message(
            encrypted["ciphertext"],
            encrypted["nonce"],
            recipient["private_key"],
            sender["public_key"],
        )

        assert decrypted == plaintext

    def test_empty_message(self):
        """Test encryption of empty message."""
        sender = EncryptionService.generate_keypair()
        recipient = EncryptionService.generate_keypair()

        encrypted = EncryptionService.encrypt_message(
            "",
            sender["private_key"],
            recipient["public_key"],
        )

        decrypted = EncryptionService.decrypt_message(
            encrypted["ciphertext"],
            encrypted["nonce"],
            recipient["private_key"],
            sender["public_key"],
        )

        assert decrypted == ""
