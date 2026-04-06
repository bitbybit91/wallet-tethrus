"""TRON/TRC20 network integration service.

Provides wallet generation, balance checking, transaction construction,
and transaction monitoring for USDT-TRC20 on the TRON network.
Uses the TronGrid API with configurable supernode RPC endpoints.
"""

import hashlib
import logging
import os
import secrets
import time
from typing import Optional

import base58
import coincurve
import requests

logger = logging.getLogger(__name__)


class TronService:
    """Service for interacting with the TRON blockchain network."""

    # USDT TRC20 contract ABI function selectors
    TRANSFER_SELECTOR = "a9059cbb"
    BALANCE_OF_SELECTOR = "70a08231"

    def __init__(self, app=None):
        """Initialize TronService with optional Flask app."""
        self.api_url = "https://api.trongrid.io"
        self.api_key = ""
        self.rpc_endpoints = []
        self.usdt_contract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        if app:
            self.init_app(app)

    def init_app(self, app):
        """Initialize with Flask application configuration."""
        self.api_url = app.config.get(
            "TRONGRID_API_URL", self.api_url
        )
        self.api_key = app.config.get("TRONGRID_API_KEY", "")
        self.rpc_endpoints = app.config.get(
            "TRON_RPC_ENDPOINTS", [self.api_url]
        )
        self.usdt_contract = app.config.get(
            "USDT_CONTRACT_ADDRESS", self.usdt_contract
        )

    def _get_headers(self):
        """Get request headers with optional API key."""
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["TRON-PRO-API-KEY"] = self.api_key
        return headers

    def _api_request(self, method, path, data=None, timeout=15):
        """Make an API request with endpoint fallback.

        Tries the primary endpoint first, then falls back to
        configured backup RPC endpoints.
        """
        endpoints = [self.api_url] + [
            ep for ep in self.rpc_endpoints if ep != self.api_url
        ]
        last_error = None

        for endpoint in endpoints:
            url = f"{endpoint}{path}"
            try:
                if method == "GET":
                    resp = requests.get(
                        url,
                        headers=self._get_headers(),
                        timeout=timeout,
                    )
                else:
                    resp = requests.post(
                        url,
                        json=data,
                        headers=self._get_headers(),
                        timeout=timeout,
                    )
                resp.raise_for_status()
                return resp.json()
            except requests.RequestException as e:
                last_error = e
                logger.warning(
                    "RPC endpoint %s failed: %s", endpoint, str(e)
                )
                continue

        logger.error("All RPC endpoints failed")
        raise ConnectionError(
            f"All TRON RPC endpoints unavailable: {last_error}"
        )

    @staticmethod
    def generate_keypair():
        """Generate a new TRON-compatible keypair.

        Returns:
            dict with 'private_key', 'public_key', and 'address'
        """
        # Generate private key using secp256k1 via coincurve
        private_key = coincurve.PrivateKey()
        private_key_hex = private_key.secret.hex()

        # Derive uncompressed public key (65 bytes: 04 || x || y)
        # Strip the 04 prefix for address derivation
        public_key_uncompressed = private_key.public_key.format(
            compressed=False
        )
        public_key_bytes = public_key_uncompressed[1:]  # Remove 04

        # TRON address: Keccak-256 hash of public key, take last 20 bytes
        keccak = hashlib.sha3_256(public_key_bytes).digest()
        # TRON uses a custom Keccak-256 variant; for compatibility,
        # we use the standard approach with 0x41 prefix
        address_bytes = b"\x41" + keccak[-20:]

        # Base58Check encode
        checksum = hashlib.sha256(
            hashlib.sha256(address_bytes).digest()
        ).digest()[:4]
        address = base58.b58encode(address_bytes + checksum).decode()

        return {
            "private_key": private_key_hex,
            "public_key": public_key_bytes.hex(),
            "address": address,
        }

    @staticmethod
    def address_from_private_key(private_key_hex):
        """Derive TRON address from a private key.

        Args:
            private_key_hex: Hexadecimal private key string

        Returns:
            TRON base58check address string
        """
        private_key = coincurve.PrivateKey(
            bytes.fromhex(private_key_hex)
        )
        public_key_uncompressed = private_key.public_key.format(
            compressed=False
        )
        public_key_bytes = public_key_uncompressed[1:]  # Remove 04

        keccak = hashlib.sha3_256(public_key_bytes).digest()
        address_bytes = b"\x41" + keccak[-20:]

        checksum = hashlib.sha256(
            hashlib.sha256(address_bytes).digest()
        ).digest()[:4]
        return base58.b58encode(address_bytes + checksum).decode()

    @staticmethod
    def validate_address(address):
        """Validate a TRON address format.

        Args:
            address: TRON base58check address string

        Returns:
            bool indicating if address is valid
        """
        try:
            decoded = base58.b58decode(address)
            if len(decoded) != 25:
                return False
            if decoded[0:1] != b"\x41":
                return False
            payload = decoded[:-4]
            checksum = decoded[-4:]
            expected = hashlib.sha256(
                hashlib.sha256(payload).digest()
            ).digest()[:4]
            return checksum == expected
        except Exception:
            return False

    def get_trx_balance(self, address):
        """Get TRX balance for an address.

        Args:
            address: TRON address

        Returns:
            Balance in TRX (float, 6 decimal places)
        """
        try:
            result = self._api_request(
                "POST",
                "/wallet/getaccount",
                {"address": address, "visible": True},
            )
            balance = result.get("balance", 0)
            return balance / 1_000_000  # TRX has 6 decimals
        except Exception as e:
            logger.error("Failed to get TRX balance: %s", str(e))
            return 0.0

    def get_usdt_balance(self, address):
        """Get USDT-TRC20 balance for an address.

        Args:
            address: TRON address

        Returns:
            USDT balance as float (6 decimal places)
        """
        try:
            # Encode the balanceOf call
            address_hex = self._address_to_hex(address)
            parameter = address_hex.zfill(64)

            result = self._api_request(
                "POST",
                "/wallet/triggersmartcontract",
                {
                    "owner_address": address,
                    "contract_address": self.usdt_contract,
                    "function_selector": "balanceOf(address)",
                    "parameter": parameter,
                    "visible": True,
                },
            )

            if result.get("result", {}).get("result"):
                constant_result = result.get(
                    "constant_result", ["0"]
                )
                if constant_result and constant_result[0]:
                    balance_hex = constant_result[0]
                    balance = int(balance_hex, 16)
                    return balance / 1_000_000  # USDT has 6 decimals
            return 0.0
        except Exception as e:
            logger.error("Failed to get USDT balance: %s", str(e))
            return 0.0

    def build_usdt_transfer(
        self, from_address, to_address, amount_usdt, private_key=None
    ):
        """Build a USDT-TRC20 transfer transaction.

        Args:
            from_address: Sender's TRON address
            to_address: Recipient's TRON address
            amount_usdt: Amount of USDT to transfer
            private_key: Optional private key for signing

        Returns:
            dict with transaction data (unsigned if no private key)
        """
        try:
            # Convert amount to smallest unit (6 decimals)
            amount_sun = int(amount_usdt * 1_000_000)

            # Encode transfer parameters
            to_hex = self._address_to_hex(to_address).zfill(64)
            amount_hex = hex(amount_sun)[2:].zfill(64)
            parameter = to_hex + amount_hex

            # Build the transaction
            result = self._api_request(
                "POST",
                "/wallet/triggersmartcontract",
                {
                    "owner_address": from_address,
                    "contract_address": self.usdt_contract,
                    "function_selector": "transfer(address,uint256)",
                    "parameter": parameter,
                    "fee_limit": 100_000_000,  # 100 TRX max fee
                    "visible": True,
                },
            )

            if not result.get("result", {}).get("result"):
                error_msg = result.get("result", {}).get(
                    "message", "Unknown error"
                )
                raise ValueError(
                    f"Transaction build failed: {error_msg}"
                )

            transaction = result.get("transaction", {})

            if private_key:
                # Sign and broadcast
                signed = self._sign_transaction(
                    transaction, private_key
                )
                broadcast = self._api_request(
                    "POST",
                    "/wallet/broadcasttransaction",
                    signed,
                )
                return {
                    "success": broadcast.get("result", False),
                    "tx_id": transaction.get("txID"),
                    "transaction": signed,
                }

            # Return unsigned transaction for external signing
            return {
                "success": True,
                "tx_id": transaction.get("txID"),
                "transaction": transaction,
                "unsigned": True,
            }

        except Exception as e:
            logger.error("USDT transfer failed: %s", str(e))
            return {"success": False, "error": str(e)}

    def get_transaction_info(self, tx_id):
        """Get transaction information and confirmation status.

        Args:
            tx_id: Transaction hash/ID

        Returns:
            dict with transaction details and confirmation count
        """
        try:
            result = self._api_request(
                "POST",
                "/wallet/gettransactioninfobyid",
                {"value": tx_id},
            )
            if not result:
                return None

            # Get current block for confirmation count
            block = self._api_request(
                "POST", "/wallet/getnowblock", {}
            )
            current_block = (
                block.get("block_header", {})
                .get("raw_data", {})
                .get("number", 0)
            )
            tx_block = result.get("blockNumber", 0)
            confirmations = (
                max(0, current_block - tx_block) if tx_block else 0
            )

            return {
                "tx_id": tx_id,
                "block_number": tx_block,
                "confirmations": confirmations,
                "fee": result.get("fee", 0) / 1_000_000,
                "result": result.get("result", ""),
                "receipt": result.get("receipt", {}),
                "timestamp": result.get("blockTimeStamp", 0),
            }
        except Exception as e:
            logger.error("Failed to get tx info: %s", str(e))
            return None

    def monitor_transaction(self, tx_id, required_confirmations=20):
        """Check if a transaction has sufficient confirmations.

        Args:
            tx_id: Transaction hash/ID
            required_confirmations: Number of confirmations needed

        Returns:
            dict with confirmation status
        """
        info = self.get_transaction_info(tx_id)
        if not info:
            return {
                "confirmed": False,
                "confirmations": 0,
                "exists": False,
            }

        return {
            "confirmed": (
                info["confirmations"] >= required_confirmations
            ),
            "confirmations": info["confirmations"],
            "exists": True,
            "block_number": info["block_number"],
        }

    def _sign_transaction(self, transaction, private_key):
        """Sign a transaction with a private key.

        Args:
            transaction: Unsigned transaction dict
            private_key: Hex-encoded private key

        Returns:
            Signed transaction dict
        """
        tx_id = transaction.get("txID", "")
        tx_id_bytes = bytes.fromhex(tx_id)

        sk = coincurve.PrivateKey(bytes.fromhex(private_key))
        # Sign with recoverable signature (65 bytes: r + s + v)
        signature = sk.sign_recoverable(
            tx_id_bytes, hasher=None
        )
        # coincurve returns r(32) + s(32) + recovery_id(1)
        signature_hex = signature.hex()

        transaction["signature"] = [signature_hex]
        return transaction

    @staticmethod
    def _address_to_hex(address):
        """Convert TRON base58 address to hex (without 41 prefix).

        Args:
            address: TRON base58check address

        Returns:
            Hex string of the address (20 bytes, no prefix)
        """
        decoded = base58.b58decode(address)
        # Remove version byte (41) and checksum (4 bytes)
        return decoded[1:-4].hex()
