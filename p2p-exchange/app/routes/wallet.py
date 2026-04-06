"""Wallet routes for TRON/TRC20 operations.

Provides endpoints for wallet generation, balance checking,
transaction building, and transaction monitoring.
"""

import logging

from flask import Blueprint, jsonify, request

from app.routes.auth import require_auth

logger = logging.getLogger(__name__)

wallet_bp = Blueprint("wallet", __name__, url_prefix="/api/wallet")


@wallet_bp.route("/generate", methods=["POST"])
def generate_wallet():
    """Generate a new TRON-compatible wallet.

    Creates a new keypair and returns the address, public key,
    and private key. The private key is shown once and never
    stored on the server.

    Returns:
        JSON with wallet address, public_key, and private_key
    """
    from app.main import tron_service

    wallet = tron_service.generate_keypair()

    return jsonify({
        "success": True,
        "wallet": {
            "address": wallet["address"],
            "public_key": wallet["public_key"],
            "private_key": wallet["private_key"],
        },
        "warning": (
            "Save your private key securely. "
            "It will NOT be stored on this server."
        ),
    })


@wallet_bp.route("/balance/<address>", methods=["GET"])
def get_balance(address):
    """Get TRX and USDT-TRC20 balances for an address.

    Args:
        address: TRON wallet address

    Returns:
        JSON with TRX and USDT balances
    """
    from app.main import tron_service

    if not tron_service.validate_address(address):
        return jsonify({
            "success": False,
            "error": "Invalid TRON address",
        }), 400

    trx_balance = tron_service.get_trx_balance(address)
    usdt_balance = tron_service.get_usdt_balance(address)

    return jsonify({
        "success": True,
        "address": address,
        "balances": {
            "trx": trx_balance,
            "usdt": usdt_balance,
        },
    })


@wallet_bp.route("/validate/<address>", methods=["GET"])
def validate_address(address):
    """Validate a TRON address format.

    Args:
        address: TRON wallet address to validate

    Returns:
        JSON with validation result
    """
    from app.main import tron_service

    is_valid = tron_service.validate_address(address)

    return jsonify({
        "success": True,
        "address": address,
        "valid": is_valid,
    })


@wallet_bp.route("/send", methods=["POST"])
@require_auth
def send_usdt(user):
    """Build a USDT-TRC20 transfer transaction.

    If a private key is provided, the transaction is signed and
    broadcast. Otherwise, returns the unsigned transaction for
    external signing (hardware wallet support).

    Request body:
        from_address: Sender's TRON address
        to_address: Recipient's TRON address
        amount: Amount of USDT to send
        private_key: Optional private key for signing

    Returns:
        JSON with transaction details
    """
    from app.main import tron_service

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    required = ["from_address", "to_address", "amount"]
    for field in required:
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} is required",
            }), 400

    # Validate addresses
    if not tron_service.validate_address(data["from_address"]):
        return jsonify({
            "success": False,
            "error": "Invalid sender address",
        }), 400

    if not tron_service.validate_address(data["to_address"]):
        return jsonify({
            "success": False,
            "error": "Invalid recipient address",
        }), 400

    amount = float(data["amount"])
    if amount <= 0:
        return jsonify({
            "success": False,
            "error": "Amount must be positive",
        }), 400

    result = tron_service.build_usdt_transfer(
        from_address=data["from_address"],
        to_address=data["to_address"],
        amount_usdt=amount,
        private_key=data.get("private_key"),
    )

    return jsonify(result)


@wallet_bp.route("/tx/<tx_id>", methods=["GET"])
def get_transaction(tx_id):
    """Get transaction information and confirmation status.

    Args:
        tx_id: Transaction hash/ID

    Returns:
        JSON with transaction details
    """
    from app.main import tron_service

    info = tron_service.get_transaction_info(tx_id)
    if not info:
        return jsonify({
            "success": False,
            "error": "Transaction not found",
        }), 404

    return jsonify({
        "success": True,
        "transaction": info,
    })


@wallet_bp.route("/tx/<tx_id>/confirm", methods=["GET"])
def check_confirmations(tx_id):
    """Check transaction confirmation status.

    Query parameters:
        required: Number of required confirmations (default: 20)

    Args:
        tx_id: Transaction hash/ID

    Returns:
        JSON with confirmation status
    """
    from app.main import tron_service

    required = request.args.get("required", 20, type=int)
    result = tron_service.monitor_transaction(tx_id, required)

    return jsonify({
        "success": True,
        "tx_id": tx_id,
        **result,
    })
