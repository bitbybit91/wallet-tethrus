"""Trade model for P2P trade lifecycle management."""

import time

from app.main import db


class Trade(db.Model):
    """A P2P trade between a buyer and seller.

    Tracks the full lifecycle of a trade from initiation through
    escrow funding, fiat payment, and final release or dispute.
    """

    __tablename__ = "trades"

    id = db.Column(db.Integer, primary_key=True)
    offer_id = db.Column(
        db.Integer, db.ForeignKey("offers.id"), nullable=False, index=True
    )
    buyer_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False, index=True
    )
    seller_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False, index=True
    )
    amount_usdt = db.Column(db.Float, nullable=False)
    price_per_usdt = db.Column(db.Float, nullable=False)
    total_fiat = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(10), nullable=False)

    # Wallet addresses
    buyer_address = db.Column(db.String(42), nullable=False)
    seller_address = db.Column(db.String(42), nullable=True)
    escrow_address = db.Column(db.String(42), nullable=True)

    # Escrow transaction tracking
    escrow_tx_id = db.Column(db.String(128), nullable=True)
    escrow_confirmed = db.Column(db.Boolean, default=False, nullable=False)
    release_tx_id = db.Column(db.String(128), nullable=True)

    # Trade status
    status = db.Column(
        db.String(20), nullable=False, default="initiated", index=True
    )
    # Status flow:
    # initiated -> escrow_pending -> escrow_funded -> fiat_sent ->
    # fiat_confirmed -> completed
    # Any state can transition to: disputed, cancelled, expired

    # Dispute fields
    dispute_reason = db.Column(db.Text, nullable=True)
    dispute_opened_by = db.Column(db.Integer, nullable=True)
    dispute_resolution = db.Column(db.Text, nullable=True)
    arbitrator_id = db.Column(db.Integer, nullable=True)

    # Timestamps
    created_at = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )
    escrow_funded_at = db.Column(db.Float, nullable=True)
    fiat_sent_at = db.Column(db.Float, nullable=True)
    fiat_confirmed_at = db.Column(db.Float, nullable=True)
    completed_at = db.Column(db.Float, nullable=True)
    disputed_at = db.Column(db.Float, nullable=True)
    expires_at = db.Column(db.Float, nullable=True)

    # Chat encryption
    buyer_chat_pubkey = db.Column(db.String(128), nullable=True)
    seller_chat_pubkey = db.Column(db.String(128), nullable=True)

    # Relationships
    messages = db.relationship("Message", backref="trade", lazy="dynamic")

    VALID_STATUSES = [
        "initiated",
        "escrow_pending",
        "escrow_funded",
        "fiat_sent",
        "fiat_confirmed",
        "completed",
        "disputed",
        "cancelled",
        "expired",
    ]

    VALID_TRANSITIONS = {
        "initiated": ["escrow_pending", "cancelled", "expired"],
        "escrow_pending": [
            "escrow_funded", "cancelled", "expired", "disputed",
        ],
        "escrow_funded": ["fiat_sent", "cancelled", "expired", "disputed"],
        "fiat_sent": ["fiat_confirmed", "disputed", "expired"],
        "fiat_confirmed": ["completed", "disputed"],
        "disputed": ["completed", "cancelled"],
    }

    def can_transition_to(self, new_status):
        """Check if transition to new status is valid."""
        allowed = self.VALID_TRANSITIONS.get(self.status, [])
        return new_status in allowed

    def to_dict(self):
        """Serialize trade to dictionary."""
        return {
            "id": self.id,
            "offer_id": self.offer_id,
            "buyer_id": self.buyer_id,
            "seller_id": self.seller_id,
            "buyer_nickname": (
                self.buyer.nickname if self.buyer else None
            ),
            "seller_nickname": (
                self.seller.nickname if self.seller else None
            ),
            "amount_usdt": self.amount_usdt,
            "price_per_usdt": self.price_per_usdt,
            "total_fiat": self.total_fiat,
            "currency": self.currency,
            "buyer_address": self.buyer_address,
            "escrow_address": self.escrow_address,
            "escrow_tx_id": self.escrow_tx_id,
            "escrow_confirmed": self.escrow_confirmed,
            "release_tx_id": self.release_tx_id,
            "status": self.status,
            "dispute_reason": self.dispute_reason,
            "created_at": self.created_at,
            "escrow_funded_at": self.escrow_funded_at,
            "fiat_sent_at": self.fiat_sent_at,
            "fiat_confirmed_at": self.fiat_confirmed_at,
            "completed_at": self.completed_at,
            "disputed_at": self.disputed_at,
            "expires_at": self.expires_at,
            "buyer_chat_pubkey": self.buyer_chat_pubkey,
            "seller_chat_pubkey": self.seller_chat_pubkey,
        }

    def __repr__(self):
        return (
            f"<Trade {self.id} {self.amount_usdt} USDT "
            f"[{self.status}]>"
        )
