"""Message model for E2E encrypted trade chat."""

import time

from app.main import db


class Message(db.Model):
    """Encrypted chat message within a trade.

    The server only stores encrypted ciphertext and metadata.
    Plaintext content is never stored or accessible server-side.
    """

    __tablename__ = "messages"

    id = db.Column(db.Integer, primary_key=True)
    trade_id = db.Column(
        db.Integer, db.ForeignKey("trades.id"), nullable=False, index=True
    )
    sender_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )
    # Encrypted message content (base64-encoded ciphertext)
    ciphertext = db.Column(db.Text, nullable=False)
    # Sender's ephemeral public key for this message (base64-encoded)
    ephemeral_pubkey = db.Column(db.String(128), nullable=False)
    # Nonce used for encryption (base64-encoded)
    nonce = db.Column(db.String(64), nullable=False)
    # Message type: 'text', 'system', 'evidence'
    message_type = db.Column(
        db.String(16), nullable=False, default="text"
    )
    timestamp = db.Column(
        db.Float, nullable=False, default=lambda: time.time()
    )

    sender = db.relationship("User", backref="messages_sent")

    def to_dict(self):
        """Serialize message to dictionary."""
        return {
            "id": self.id,
            "trade_id": self.trade_id,
            "sender_id": self.sender_id,
            "sender_nickname": (
                self.sender.nickname if self.sender else None
            ),
            "ciphertext": self.ciphertext,
            "ephemeral_pubkey": self.ephemeral_pubkey,
            "nonce": self.nonce,
            "message_type": self.message_type,
            "timestamp": self.timestamp,
        }

    def __repr__(self):
        return f"<Message {self.id} trade={self.trade_id}>"
