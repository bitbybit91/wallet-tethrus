"""User model for pseudonymous identity management."""

import hashlib
import hmac
import secrets
import time

from app.main import db


class User(db.Model):
    """Pseudonymous user identity.

    Users are identified by session tokens and optional persistent identities
    derived from BIP39 mnemonic phrases. No personal information is stored.
    """

    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    nickname = db.Column(db.String(64), nullable=False, index=True)
    session_token = db.Column(
        db.String(128), unique=True, nullable=False, index=True
    )
    public_key = db.Column(db.String(128), unique=True, nullable=True)
    public_key_hex = db.Column(db.String(256), nullable=True)
    created_at = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )
    last_seen = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )
    is_arbitrator = db.Column(db.Boolean, default=False, nullable=False)

    # Reputation fields
    total_trades = db.Column(db.Integer, default=0, nullable=False)
    successful_trades = db.Column(db.Integer, default=0, nullable=False)
    disputed_trades = db.Column(db.Integer, default=0, nullable=False)
    total_response_time = db.Column(db.Float, default=0.0, nullable=False)
    trust_score = db.Column(db.Float, default=0.0, nullable=False)

    # Relationships
    offers = db.relationship("Offer", backref="user", lazy="dynamic")
    trades_as_buyer = db.relationship(
        "Trade",
        foreign_keys="Trade.buyer_id",
        backref="buyer",
        lazy="dynamic",
    )
    trades_as_seller = db.relationship(
        "Trade",
        foreign_keys="Trade.seller_id",
        backref="seller",
        lazy="dynamic",
    )

    @property
    def success_rate(self):
        """Calculate trade success rate as a percentage."""
        if self.total_trades == 0:
            return 0.0
        return round(
            (self.successful_trades / self.total_trades) * 100, 1
        )

    @property
    def avg_response_time(self):
        """Calculate average response time in minutes."""
        if self.total_trades == 0:
            return 0.0
        return round(self.total_response_time / self.total_trades, 1)

    @staticmethod
    def generate_session_token():
        """Generate a cryptographically secure session token."""
        return secrets.token_hex(64)

    @staticmethod
    def generate_nickname():
        """Generate a random pseudonymous nickname."""
        adjectives = [
            "Swift", "Silent", "Bright", "Dark", "Quick", "Calm",
            "Bold", "Keen", "Wild", "Free", "Sharp", "Wise",
            "Brave", "Fair", "True", "Pure", "Deep", "High",
        ]
        nouns = [
            "Wolf", "Hawk", "Bear", "Fox", "Deer", "Owl",
            "Lion", "Eagle", "Shark", "Tiger", "Raven", "Cobra",
            "Falcon", "Viper", "Lynx", "Orca", "Puma", "Crane",
        ]
        adj = secrets.choice(adjectives)
        noun = secrets.choice(nouns)
        num = secrets.randbelow(10000)
        return f"{adj}{noun}{num:04d}"

    @staticmethod
    def verify_session_token(token):
        """Verify and return user by session token."""
        if not token or len(token) != 128:
            return None
        return User.query.filter_by(session_token=token).first()

    def to_dict(self, include_private=False):
        """Serialize user to dictionary."""
        data = {
            "id": self.id,
            "nickname": self.nickname,
            "created_at": self.created_at,
            "last_seen": self.last_seen,
            "total_trades": self.total_trades,
            "successful_trades": self.successful_trades,
            "success_rate": self.success_rate,
            "avg_response_time": self.avg_response_time,
            "trust_score": self.trust_score,
            "is_arbitrator": self.is_arbitrator,
        }
        if include_private:
            data["session_token"] = self.session_token
            data["public_key"] = self.public_key
        return data

    def __repr__(self):
        return f"<User {self.nickname}>"
