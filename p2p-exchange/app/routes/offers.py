"""Offer routes for creating and managing buy/sell listings.

Provides CRUD operations for trading offers with filtering
and search capabilities.
"""

import json
import logging
import time

from flask import Blueprint, jsonify, request

from app.routes.auth import get_current_user, require_auth

logger = logging.getLogger(__name__)

offers_bp = Blueprint("offers", __name__, url_prefix="/api/offers")


@offers_bp.route("", methods=["GET"])
def list_offers():
    """List active offers with optional filtering.

    Query parameters:
        type: 'buy' or 'sell'
        currency: Fiat currency code (e.g., 'USD', 'EUR')
        payment_method: Filter by payment method
        location: Filter by location
        min_amount: Minimum trade amount
        max_amount: Maximum trade amount
        sort: Sort field ('price', 'created_at', 'trust_score')
        order: Sort order ('asc' or 'desc')
        page: Page number (default: 1)
        per_page: Results per page (default: 20, max: 100)

    Returns:
        JSON with list of matching offers
    """
    from app.models.offer import Offer

    query = Offer.query.filter_by(status="active")

    # Apply filters
    offer_type = request.args.get("type")
    if offer_type in ("buy", "sell"):
        query = query.filter_by(offer_type=offer_type)

    currency = request.args.get("currency")
    if currency:
        query = query.filter_by(currency=currency.upper())

    location = request.args.get("location")
    if location:
        query = query.filter(
            Offer.location.ilike(f"%{location}%")
        )

    min_amount = request.args.get("min_amount", type=float)
    if min_amount is not None:
        query = query.filter(Offer.amount_max >= min_amount)

    max_amount = request.args.get("max_amount", type=float)
    if max_amount is not None:
        query = query.filter(Offer.amount_min <= max_amount)

    # Sorting
    sort_field = request.args.get("sort", "created_at")
    sort_order = request.args.get("order", "desc")

    if sort_field == "price":
        order_col = Offer.price_per_usdt
    elif sort_field == "trust_score":
        order_col = Offer.user_id  # Will be joined
    else:
        order_col = Offer.created_at

    if sort_order == "asc":
        query = query.order_by(order_col.asc())
    else:
        query = query.order_by(order_col.desc())

    # Pagination
    page = request.args.get("page", 1, type=int)
    per_page = min(
        request.args.get("per_page", 20, type=int), 100
    )

    pagination = query.paginate(
        page=page, per_page=per_page, error_out=False
    )

    # Filter by payment method (JSON field)
    payment_method = request.args.get("payment_method")
    offers = []
    for offer in pagination.items:
        if payment_method:
            methods = json.loads(offer.payment_methods)
            if payment_method.lower() not in [
                m.lower() for m in methods
            ]:
                continue
        offers.append(offer.to_dict())

    return jsonify({
        "success": True,
        "offers": offers,
        "pagination": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": pagination.total,
            "pages": pagination.pages,
        },
    })


@offers_bp.route("", methods=["POST"])
@require_auth
def create_offer(user):
    """Create a new buy or sell offer.

    Request body:
        offer_type: 'buy' or 'sell'
        amount_min: Minimum USDT amount
        amount_max: Maximum USDT amount
        price_per_usdt: Price per USDT in fiat
        currency: Fiat currency code
        payment_methods: List of accepted payment methods
        terms: Optional trade terms text
        location: Optional location string

    Returns:
        JSON with created offer details
    """
    from app.main import db
    from app.models.offer import Offer

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    # Validate required fields
    required = [
        "offer_type", "amount_min", "amount_max",
        "price_per_usdt", "currency", "payment_methods",
    ]
    for field in required:
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} is required",
            }), 400

    if data["offer_type"] not in ("buy", "sell"):
        return jsonify({
            "success": False,
            "error": "offer_type must be 'buy' or 'sell'",
        }), 400

    if data["amount_min"] <= 0 or data["amount_max"] <= 0:
        return jsonify({
            "success": False,
            "error": "Amounts must be positive",
        }), 400

    if data["amount_min"] > data["amount_max"]:
        return jsonify({
            "success": False,
            "error": "amount_min cannot exceed amount_max",
        }), 400

    if data["price_per_usdt"] <= 0:
        return jsonify({
            "success": False,
            "error": "Price must be positive",
        }), 400

    if not isinstance(data["payment_methods"], list):
        return jsonify({
            "success": False,
            "error": "payment_methods must be a list",
        }), 400

    offer = Offer(
        user_id=user.id,
        offer_type=data["offer_type"],
        amount_min=float(data["amount_min"]),
        amount_max=float(data["amount_max"]),
        price_per_usdt=float(data["price_per_usdt"]),
        currency=data["currency"].upper(),
        payment_methods=json.dumps(data["payment_methods"]),
        terms=data.get("terms", ""),
        location=data.get("location", ""),
    )

    db.session.add(offer)
    db.session.commit()

    logger.info(
        "Offer created: %s %s by %s",
        offer.offer_type,
        offer.id,
        user.nickname,
    )

    return jsonify({
        "success": True,
        "offer": offer.to_dict(),
    }), 201


@offers_bp.route("/<int:offer_id>", methods=["GET"])
def get_offer(offer_id):
    """Get details of a specific offer.

    Args:
        offer_id: ID of the offer

    Returns:
        JSON with offer details
    """
    from app.models.offer import Offer

    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({
            "success": False,
            "error": "Offer not found",
        }), 404

    return jsonify({
        "success": True,
        "offer": offer.to_dict(),
    })


@offers_bp.route("/<int:offer_id>", methods=["PUT"])
@require_auth
def update_offer(user, offer_id):
    """Update an existing offer.

    Only the offer owner can update their offer.

    Args:
        offer_id: ID of the offer to update

    Returns:
        JSON with updated offer details
    """
    from app.main import db
    from app.models.offer import Offer

    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({
            "success": False,
            "error": "Offer not found",
        }), 404

    if offer.user_id != user.id:
        return jsonify({
            "success": False,
            "error": "Not authorized to update this offer",
        }), 403

    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    # Update allowed fields
    if "amount_min" in data:
        offer.amount_min = float(data["amount_min"])
    if "amount_max" in data:
        offer.amount_max = float(data["amount_max"])
    if "price_per_usdt" in data:
        offer.price_per_usdt = float(data["price_per_usdt"])
    if "payment_methods" in data:
        offer.payment_methods = json.dumps(
            data["payment_methods"]
        )
    if "terms" in data:
        offer.terms = data["terms"]
    if "location" in data:
        offer.location = data["location"]
    if "status" in data and data["status"] in (
        "active", "paused", "closed",
    ):
        offer.status = data["status"]

    offer.updated_at = time.time()
    db.session.commit()

    return jsonify({
        "success": True,
        "offer": offer.to_dict(),
    })


@offers_bp.route("/<int:offer_id>", methods=["DELETE"])
@require_auth
def delete_offer(user, offer_id):
    """Delete (close) an offer.

    Only the offer owner can delete their offer.
    Active trades prevent deletion.

    Args:
        offer_id: ID of the offer to delete

    Returns:
        JSON with success status
    """
    from app.main import db
    from app.models.offer import Offer

    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({
            "success": False,
            "error": "Offer not found",
        }), 404

    if offer.user_id != user.id:
        return jsonify({
            "success": False,
            "error": "Not authorized to delete this offer",
        }), 403

    # Check for active trades
    active_trades = offer.trades.filter(
        ~__import__("app.models.trade", fromlist=["Trade"])
        .Trade.status.in_(
            ["completed", "cancelled", "expired"]
        )
    ).count()

    if active_trades > 0:
        return jsonify({
            "success": False,
            "error": "Cannot delete offer with active trades",
        }), 409

    offer.status = "closed"
    offer.updated_at = time.time()
    db.session.commit()

    return jsonify({"success": True})


@offers_bp.route("/my", methods=["GET"])
@require_auth
def my_offers(user):
    """List the current user's offers.

    Returns:
        JSON with list of user's offers
    """
    offers = [o.to_dict() for o in user.offers.all()]
    return jsonify({
        "success": True,
        "offers": offers,
    })
