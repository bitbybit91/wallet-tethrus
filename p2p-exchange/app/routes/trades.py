"""Trade routes for P2P trade lifecycle management.

Provides endpoints for initiating trades, managing escrow,
confirming payments, and handling disputes.
"""

import logging
import time

from flask import Blueprint, jsonify, request

from app.routes.auth import get_current_user, require_auth

logger = logging.getLogger(__name__)

trades_bp = Blueprint("trades", __name__, url_prefix="/api/trades")


@trades_bp.route("", methods=["POST"])
@require_auth
def initiate_trade(user):
    """Initiate a new trade against an existing offer.

    Request body:
        offer_id: ID of the offer to trade against
        amount_usdt: Amount of USDT to trade
        buyer_address: Buyer's TRON wallet address

    Returns:
        JSON with trade details and escrow information
    """
    from app.main import db, escrow_service, tron_service
    from app.models.offer import Offer
    from app.models.trade import Trade

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    required = ["offer_id", "amount_usdt", "buyer_address"]
    for field in required:
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} is required",
            }), 400

    offer = Offer.query.get(data["offer_id"])
    if not offer:
        return jsonify({
            "success": False,
            "error": "Offer not found",
        }), 404

    if offer.status != "active":
        return jsonify({
            "success": False,
            "error": "Offer is not active",
        }), 400

    if offer.user_id == user.id:
        return jsonify({
            "success": False,
            "error": "Cannot trade against your own offer",
        }), 400

    amount = float(data["amount_usdt"])
    if amount < offer.amount_min or amount > offer.amount_max:
        return jsonify({
            "success": False,
            "error": (
                f"Amount must be between "
                f"{offer.amount_min} and {offer.amount_max}"
            ),
        }), 400

    # Validate buyer address
    if not tron_service.validate_address(data["buyer_address"]):
        return jsonify({
            "success": False,
            "error": "Invalid TRON address",
        }), 400

    # Determine buyer/seller based on offer type
    if offer.offer_type == "sell":
        buyer_id = user.id
        seller_id = offer.user_id
    else:
        buyer_id = offer.user_id
        seller_id = user.id

    total_fiat = amount * offer.price_per_usdt

    trade = Trade(
        offer_id=offer.id,
        buyer_id=buyer_id,
        seller_id=seller_id,
        amount_usdt=amount,
        price_per_usdt=offer.price_per_usdt,
        total_fiat=total_fiat,
        currency=offer.currency,
        buyer_address=data["buyer_address"],
        status="initiated",
    )

    db.session.add(trade)
    db.session.commit()

    # Create escrow
    escrow_info = escrow_service.create_escrow(trade)

    logger.info(
        "Trade initiated: %d (%s USDT)",
        trade.id,
        amount,
    )

    return jsonify({
        "success": True,
        "trade": trade.to_dict(),
        "escrow": escrow_info,
    }), 201


@trades_bp.route("/<int:trade_id>", methods=["GET"])
@require_auth
def get_trade(user, trade_id):
    """Get details of a specific trade.

    Only trade participants can view trade details.

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with trade details
    """
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
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
            "error": "Not authorized to view this trade",
        }), 403

    return jsonify({
        "success": True,
        "trade": trade.to_dict(),
    })


@trades_bp.route("/<int:trade_id>/escrow/verify", methods=["POST"])
@require_auth
def verify_escrow(user, trade_id):
    """Verify escrow funding for a trade.

    Can verify by checking the escrow address balance or
    by providing a specific transaction ID.

    Request body (optional):
        tx_id: Specific transaction ID to verify

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with escrow verification status
    """
    from app.main import escrow_service
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
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

    data = request.get_json(silent=True) or {}
    tx_id = data.get("tx_id")

    if tx_id:
        result = escrow_service.verify_escrow_transaction(
            trade, tx_id
        )
    else:
        result = escrow_service.verify_escrow_funding(trade)

    return jsonify({"success": True, **result})


@trades_bp.route(
    "/<int:trade_id>/fiat-sent", methods=["POST"]
)
@require_auth
def confirm_fiat_sent(user, trade_id):
    """Buyer confirms fiat payment has been sent.

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with updated trade status
    """
    from app.main import db, notification_service
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id != trade.buyer_id:
        return jsonify({
            "success": False,
            "error": "Only the buyer can confirm fiat sent",
        }), 403

    if not trade.can_transition_to("fiat_sent"):
        return jsonify({
            "success": False,
            "error": (
                f"Cannot mark fiat sent from status: "
                f"{trade.status}"
            ),
        }), 400

    trade.status = "fiat_sent"
    trade.fiat_sent_at = time.time()
    db.session.commit()

    notification_service.notify_trade_event(
        trade, "fiat_sent"
    )

    return jsonify({
        "success": True,
        "trade": trade.to_dict(),
    })


@trades_bp.route(
    "/<int:trade_id>/fiat-received", methods=["POST"]
)
@require_auth
def confirm_fiat_received(user, trade_id):
    """Seller confirms fiat payment has been received.

    This triggers the escrow release process.

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with updated trade status
    """
    from app.main import db, notification_service
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id != trade.seller_id:
        return jsonify({
            "success": False,
            "error": "Only the seller can confirm fiat received",
        }), 403

    if not trade.can_transition_to("fiat_confirmed"):
        return jsonify({
            "success": False,
            "error": (
                f"Cannot confirm fiat from status: "
                f"{trade.status}"
            ),
        }), 400

    trade.status = "fiat_confirmed"
    trade.fiat_confirmed_at = time.time()
    db.session.commit()

    notification_service.notify_trade_event(
        trade, "fiat_confirmed"
    )

    return jsonify({
        "success": True,
        "trade": trade.to_dict(),
    })


@trades_bp.route(
    "/<int:trade_id>/release", methods=["POST"]
)
@require_auth
def release_escrow(user, trade_id):
    """Release escrowed funds to the buyer.

    The seller calls this to release USDT to the buyer's address
    after confirming fiat payment receipt.

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with release transaction details
    """
    from app.main import (
        db,
        escrow_service,
        notification_service,
    )
    from app.models.trade import Trade
    from app.services.reputation import ReputationService

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id != trade.seller_id and not user.is_arbitrator:
        return jsonify({
            "success": False,
            "error": "Not authorized to release escrow",
        }), 403

    result = escrow_service.release_escrow(
        trade, trade.buyer_address
    )

    if result.get("success"):
        # Update reputation for both parties
        ReputationService.update_after_trade(
            trade.buyer, trade, True
        )
        ReputationService.update_after_trade(
            trade.seller, trade, True
        )

        notification_service.notify_trade_event(
            trade, "escrow_released"
        )

    return jsonify(result)


@trades_bp.route(
    "/<int:trade_id>/dispute", methods=["POST"]
)
@require_auth
def open_dispute(user, trade_id):
    """Open a dispute on a trade.

    Either party can open a dispute if they believe the
    trade is not proceeding fairly.

    Request body:
        reason: Text description of the dispute

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with dispute details
    """
    from app.main import escrow_service, notification_service
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({
            "success": False,
            "error": "Only trade participants can open disputes",
        }), 403

    data = request.get_json(silent=True)
    if not data or "reason" not in data:
        return jsonify({
            "success": False,
            "error": "reason is required",
        }), 400

    result = escrow_service.open_dispute(
        trade, user.id, data["reason"]
    )

    if result.get("success"):
        notification_service.notify_trade_event(
            trade, "dispute_opened", {"reason": data["reason"]}
        )

    return jsonify(result)


@trades_bp.route(
    "/<int:trade_id>/resolve", methods=["POST"]
)
@require_auth
def resolve_dispute(user, trade_id):
    """Resolve a disputed trade (arbitrator only).

    Request body:
        resolution: Text description of the resolution
        release_to: 'buyer' or 'seller'

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with resolution details
    """
    from app.main import escrow_service, notification_service
    from app.models.trade import Trade
    from app.services.reputation import ReputationService

    if not user.is_arbitrator:
        return jsonify({
            "success": False,
            "error": "Only arbitrators can resolve disputes",
        }), 403

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({
            "success": False,
            "error": "Trade not found",
        }), 404

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    for field in ("resolution", "release_to"):
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} is required",
            }), 400

    result = escrow_service.resolve_dispute(
        trade, user.id, data["resolution"], data["release_to"]
    )

    if result.get("success"):
        # Update reputation (loser gets negative mark)
        winner_id = (
            trade.buyer_id
            if data["release_to"] == "buyer"
            else trade.seller_id
        )
        loser_id = (
            trade.seller_id
            if data["release_to"] == "buyer"
            else trade.buyer_id
        )

        from app.models.user import User

        winner = User.query.get(winner_id)
        loser = User.query.get(loser_id)
        if winner:
            ReputationService.update_after_trade(
                winner, trade, True
            )
        if loser:
            ReputationService.update_after_trade(
                loser, trade, False
            )

        notification_service.notify_trade_event(
            trade, "dispute_resolved", result
        )

    return jsonify(result)


@trades_bp.route(
    "/<int:trade_id>/cancel", methods=["POST"]
)
@require_auth
def cancel_trade(user, trade_id):
    """Cancel a trade before escrow is funded.

    Args:
        trade_id: ID of the trade

    Returns:
        JSON with updated trade status
    """
    from app.main import db, notification_service
    from app.models.trade import Trade

    trade = Trade.query.get(trade_id)
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

    if not trade.can_transition_to("cancelled"):
        return jsonify({
            "success": False,
            "error": (
                f"Cannot cancel trade in status: {trade.status}"
            ),
        }), 400

    trade.status = "cancelled"
    db.session.commit()

    notification_service.notify_trade_event(
        trade, "trade_cancelled"
    )

    return jsonify({
        "success": True,
        "trade": trade.to_dict(),
    })


@trades_bp.route("/my", methods=["GET"])
@require_auth
def my_trades(user):
    """List the current user's trades.

    Query parameters:
        status: Filter by trade status
        role: 'buyer', 'seller', or 'all' (default)

    Returns:
        JSON with list of user's trades
    """
    from app.models.trade import Trade

    role = request.args.get("role", "all")
    status = request.args.get("status")

    if role == "buyer":
        query = Trade.query.filter_by(buyer_id=user.id)
    elif role == "seller":
        query = Trade.query.filter_by(seller_id=user.id)
    else:
        query = Trade.query.filter(
            (Trade.buyer_id == user.id)
            | (Trade.seller_id == user.id)
        )

    if status:
        query = query.filter_by(status=status)

    query = query.order_by(Trade.created_at.desc())
    trades = [t.to_dict() for t in query.all()]

    return jsonify({
        "success": True,
        "trades": trades,
    })
