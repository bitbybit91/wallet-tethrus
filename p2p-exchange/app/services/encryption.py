"""End-to-end encryption service using NaCl/libsodium.

Implements X25519 key exchange with XSalsa20-Poly1305 (NaCl box)
for trade chat encryption. Each trade session generates ephemeral
keypairs for forward secrecy.
"""

import base64
import logging
import secrets

import nacl.public
import nacl.utils

logger = logging.getLogger(__name__)


class EncryptionService:
    """E2E encryption service for trade communications.

    Uses NaCl public-key authenticated encryption (Curve25519,
    XSalsa20-Poly1305) for confidential, authenticated messaging.
    """

    @staticmethod
    def generate_keypair():
        """Generate an X25519 keypair for E2E encryption.

        Returns:
            dict with base64-encoded 'private_key' and 'public_key'
        """
        private_key = nacl.public.PrivateKey.generate()
        public_key = private_key.public_key

        return {
            "private_key": base64.b64encode(
                bytes(private_key)
            ).decode(),
            "public_key": base64.b64encode(
                bytes(public_key)
            ).decode(),
        }

    @staticmethod
    def encrypt_message(
        plaintext, sender_private_key_b64, recipient_public_key_b64
    ):
        """Encrypt a message using NaCl box.

        Args:
            plaintext: Message string to encrypt
            sender_private_key_b64: Base64-encoded sender private key
            recipient_public_key_b64: Base64-encoded recipient
                                      public key

        Returns:
            dict with base64-encoded 'ciphertext' and 'nonce'
        """
        try:
            sender_key = nacl.public.PrivateKey(
                base64.b64decode(sender_private_key_b64)
            )
            recipient_key = nacl.public.PublicKey(
                base64.b64decode(recipient_public_key_b64)
            )

            box = nacl.public.Box(sender_key, recipient_key)
            nonce = nacl.utils.random(nacl.public.Box.NONCE_SIZE)
            encrypted = box.encrypt(
                plaintext.encode("utf-8"), nonce
            )

            # encrypted contains nonce + ciphertext;
            # extract just the ciphertext
            ciphertext = encrypted.ciphertext

            return {
                "ciphertext": base64.b64encode(
                    ciphertext
                ).decode(),
                "nonce": base64.b64encode(nonce).decode(),
            }
        except Exception as e:
            logger.error("Encryption failed: %s", str(e))
            raise ValueError("Encryption failed") from e

    @staticmethod
    def decrypt_message(
        ciphertext_b64,
        nonce_b64,
        recipient_private_key_b64,
        sender_public_key_b64,
    ):
        """Decrypt a message using NaCl box.

        Args:
            ciphertext_b64: Base64-encoded ciphertext
            nonce_b64: Base64-encoded nonce
            recipient_private_key_b64: Base64-encoded recipient
                                       private key
            sender_public_key_b64: Base64-encoded sender public key

        Returns:
            Decrypted plaintext string
        """
        try:
            recipient_key = nacl.public.PrivateKey(
                base64.b64decode(recipient_private_key_b64)
            )
            sender_key = nacl.public.PublicKey(
                base64.b64decode(sender_public_key_b64)
            )

            box = nacl.public.Box(recipient_key, sender_key)
            ciphertext = base64.b64decode(ciphertext_b64)
            nonce = base64.b64decode(nonce_b64)

            plaintext = box.decrypt(ciphertext, nonce)
            return plaintext.decode("utf-8")
        except Exception as e:
            logger.error("Decryption failed: %s", str(e))
            raise ValueError("Decryption failed") from e

    @staticmethod
    def generate_ephemeral_keypair():
        """Generate an ephemeral keypair for a single trade session.

        Uses the same algorithm as generate_keypair but is named
        distinctly for clarity about its intended single-use nature.

        Returns:
            dict with base64-encoded 'private_key' and 'public_key'
        """
        return EncryptionService.generate_keypair()

    @staticmethod
    def derive_shared_secret(
        private_key_b64, public_key_b64
    ):
        """Derive a shared secret from a keypair.

        Can be used for additional symmetric encryption or key
        derivation if needed.

        Args:
            private_key_b64: Base64-encoded private key
            public_key_b64: Base64-encoded public key

        Returns:
            Base64-encoded shared secret
        """
        try:
            private_key = nacl.public.PrivateKey(
                base64.b64decode(private_key_b64)
            )
            public_key = nacl.public.PublicKey(
                base64.b64decode(public_key_b64)
            )

            box = nacl.public.Box(private_key, public_key)
            # The shared key is derived internally by NaCl
            shared_key = box.encode()
            return base64.b64encode(shared_key).decode()
        except Exception as e:
            logger.error(
                "Shared secret derivation failed: %s", str(e)
            )
            raise ValueError(
                "Shared secret derivation failed"
            ) from e
