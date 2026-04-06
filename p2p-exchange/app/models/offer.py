"""Offer model for buy/sell listings."""

import time

from app.main import db


class Offer(db.Model):
    """Buy or sell offer for USDT-TRC20 trading.

    Offers represent a user's intent to buy or sell USDT-TRC20 tokens
    at a specified price using particular payment methods.
    """

    __tablename__ = "offers"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False, index=True
    )
    offer_type = db.Column(
        db.String(4), nullable=False, index=True
    )  # 'buy' or 'sell'
    amount_min = db.Column(db.Float, nullable=False)
    amount_max = db.Column(db.Float, nullable=False)
    price_per_usdt = db.Column(db.Float, nullable=False)
    currency = db.Column(
        db.String(10), nullable=False, index=True
    )  # fiat currency code
    payment_methods = db.Column(
        db.Text, nullable=False
    )  # JSON array of payment methods
    terms = db.Column(db.Text, nullable=True)
    location = db.Column(
        db.String(128), nullable=True, index=True
    )  # optional location
    status = db.Column(
        db.String(16), nullable=False, default="active", index=True
    )  # active, paused, closed
    created_at = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )
    updated_at = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )

    # Relationships
    trades = db.relationship("Trade", backref="offer", lazy="dynamic")

    def to_dict(self):
        """Serialize offer to dictionary."""
        import json

        return {
            "id": self.id,
            "user_id": self.user_id,
            "user_nickname": self.user.nickname if self.user else None,
            "user_trust_score": self.user.trust_score if self.user else 0,
            "user_total_trades": (
                self.user.total_trades if self.user else 0
            ),
            "offer_type": self.offer_type,
            "amount_min": self.amount_min,
            "amount_max": self.amount_max,
            "price_per_usdt": self.price_per_usdt,
            "currency": self.currency,
            "payment_methods": json.loads(self.payment_methods),
            "terms": self.terms,
            "location": self.location,
            "status": self.status,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }

    def __repr__(self):
        return (
            f"<Offer {self.id} {self.offer_type} "
            f"{self.amount_min}-{self.amount_max} USDT>"
        )
