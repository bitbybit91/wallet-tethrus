"""Chat routes for E2E encrypted trade messaging.

All messages are encrypted client-side before transmission.
The server only stores encrypted ciphertext, timestamps,
and sender metadata.
"""

import logging
import time

from flask import Blueprint, jsonify, request

from app.routes.auth import get_current_user, require_auth

logger = logging.getLogger(__name__)

chat_bp = Blueprint("chat", __name__, url_prefix="/api/chat")


@chat_bp.route("/<int:trade_id>/messages", methods=["GET"])
@require_auth
def get_messages(user, trade_id):
    """Get encrypted messages for a trade.

    Only trade participants and arbitrators can access messages.

    Query parameters:
        since: Unix timestamp to get messages after
        limit: Maximum number of messages (default: 50, max: 200)

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with list of encrypted messages
    """
    from app.main import db
    from app.models.message import Message
    from app.models.trade import Trade

    trade = db.session.get(Trade, trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id not in (
        trade.buyer_id, trade.seller_id,
    ) and not user.is_arbitrator:
        return jsonify({
            "success": False,
            "error": "Not authorized to view messages",
        }), 403

    query = Message.query.filter_by(trade_id=trade_id)

    since = request.args.get("since", type=float)
    if since:
        query = query.filter(Message.timestamp > since)

    limit = min(
        request.args.get("limit", 50, type=int), 200
    )
    query = query.order_by(Message.timestamp.asc()).limit(limit)

    messages = [msg.to_dict() for msg in query.all()]

    return jsonify({
        "success": True,
        "messages": messages,
        "trade_id": trade_id,
    })


@chat_bp.route("/<int:trade_id>/messages", methods=["POST"])
@require_auth
def send_message(user, trade_id):
    """Send an encrypted message in a trade chat.

    The message must be encrypted client-side before sending.
    The server stores only the ciphertext and metadata.

    Request body:
        ciphertext: Base64-encoded encrypted message
        ephemeral_pubkey: Base64-encoded sender's ephemeral
                          public key
        nonce: Base64-encoded encryption nonce
        message_type: Optional type ('text', 'evidence')

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with stored message details
    """
    from app.main import db
    from app.models.message import Message
    from app.models.trade import Trade

    trade = db.session.get(Trade, trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id not in (
        trade.buyer_id, trade.seller_id,
    ) and not user.is_arbitrator:
        return jsonify({
            "success": False,
            "error": "Not authorized to send messages",
        }), 403

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    required = ["ciphertext", "ephemeral_pubkey", "nonce"]
    for field in required:
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} is required",
            }), 400

    message_type = data.get("message_type", "text")
    if message_type not in ("text", "system", "evidence"):
        return jsonify({
            "success": False,
            "error": "Invalid message_type",
        }), 400

    msg = Message(
        trade_id=trade_id,
        sender_id=user.id,
        ciphertext=data["ciphertext"],
        ephemeral_pubkey=data["ephemeral_pubkey"],
        nonce=data["nonce"],
        message_type=message_type,
    )

    db.session.add(msg)
    db.session.commit()

    # Emit via WebSocket for real-time delivery
    try:
        from app.main import socketio

        socketio.emit(
            "new_message",
            msg.to_dict(),
            room=f"trade_{trade_id}",
        )
    except Exception as e:
        logger.warning("WebSocket emit failed: %s", e)

    return jsonify({
        "success": True,
        "message": msg.to_dict(),
    }), 201


@chat_bp.route(
    "/<int:trade_id>/pubkey", methods=["POST"]
)
@require_auth
def set_chat_pubkey(user, trade_id):
    """Set the user's chat public key for a trade session.

    Each trade session uses ephemeral keypairs for forward
    secrecy. Both parties must exchange public keys before
    encrypted communication can begin.

    Request body:
        public_key: Base64-encoded X25519 public key

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with both parties' public keys (if available)
    """
    from app.main import db
    from app.models.trade import Trade

    trade = db.session.get(Trade, trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({
            "success": False,
            "error": "Not authorized",
        }), 403

    data = request.get_json(silent=True)
    if not data or "public_key" not in data:
        return jsonify({
            "success": False,
            "error": "public_key is required",
        }), 400

    if user.id == trade.buyer_id:
        trade.buyer_chat_pubkey = data["public_key"]
    else:
        trade.seller_chat_pubkey = data["public_key"]

    db.session.commit()

    return jsonify({
        "success": True,
        "buyer_pubkey": trade.buyer_chat_pubkey,
        "seller_pubkey": trade.seller_chat_pubkey,
        "ready": bool(
            trade.buyer_chat_pubkey
            and trade.seller_chat_pubkey
        ),
    })
