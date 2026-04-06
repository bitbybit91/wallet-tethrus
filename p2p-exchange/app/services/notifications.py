"""Notification service for trade events.

Supports multiple notification channels:
- In-app browser notifications (WebSocket/SSE)
- Email (SMTP)
- Nostr protocol
- Session messenger
"""

import json
import logging
import smtplib
from email.mime.text import MIMEText

import requests

logger = logging.getLogger(__name__)


class NotificationService:
    """Multi-channel notification service for trade events."""

    def __init__(self, app=None):
        """Initialize NotificationService."""
        self.smtp_host = ""
        self.smtp_port = 587
        self.smtp_user = ""
        self.smtp_password = ""
        self.smtp_from = ""
        self.nostr_relay_url = ""
        self.session_bot_url = ""
        if app:
            self.init_app(app)

    def init_app(self, app):
        """Initialize with Flask application configuration."""
        self.smtp_host = app.config.get("SMTP_HOST", "")
        self.smtp_port = app.config.get("SMTP_PORT", 587)
        self.smtp_user = app.config.get("SMTP_USER", "")
        self.smtp_password = app.config.get("SMTP_PASSWORD", "")
        self.smtp_from = app.config.get("SMTP_FROM", "")
        self.nostr_relay_url = app.config.get(
            "NOSTR_RELAY_URL", ""
        )
        self.session_bot_url = app.config.get(
            "SESSION_BOT_API_URL", ""
        )

    def notify_trade_event(self, trade, event_type, data=None):
        """Send notification for a trade event.

        This is the primary notification dispatch method. It sends
        in-app notifications and optionally uses configured backup
        channels.

        Args:
            trade: Trade model instance
            event_type: String event type
            data: Optional additional data dict
        """
        notification = {
            "trade_id": trade.id,
            "event": event_type,
            "status": trade.status,
            "timestamp": __import__("time").time(),
            "data": data or {},
        }

        # In-app notification via WebSocket (handled by SocketIO)
        self._emit_websocket(trade, notification)

        logger.info(
            "Notification sent: trade=%d event=%s",
            trade.id,
            event_type,
        )

    def _emit_websocket(self, trade, notification):
        """Emit WebSocket notification to trade participants.

        Args:
            trade: Trade model instance
            notification: Notification dict
        """
        try:
            from app.main import socketio

            room = f"trade_{trade.id}"
            socketio.emit(
                "trade_notification",
                notification,
                room=room,
            )
        except Exception as e:
            logger.warning("WebSocket notification failed: %s", e)

    def send_email(self, to_email, subject, body):
        """Send an email notification.

        Args:
            to_email: Recipient email address
            subject: Email subject
            body: Email body text
        """
        if not self.smtp_host:
            logger.debug("SMTP not configured, skipping email")
            return

        try:
            msg = MIMEText(body)
            msg["Subject"] = subject
            msg["From"] = self.smtp_from
            msg["To"] = to_email

            with smtplib.SMTP(
                self.smtp_host, self.smtp_port
            ) as server:
                server.starttls()
                if self.smtp_user:
                    server.login(
                        self.smtp_user, self.smtp_password
                    )
                server.send_message(msg)

            logger.info("Email sent to %s", to_email)
        except Exception as e:
            logger.error("Email send failed: %s", str(e))

    def publish_nostr_event(self, event_data):
        """Publish a trade event to a Nostr relay.

        Args:
            event_data: Dict with Nostr event fields
        """
        if not self.nostr_relay_url:
            logger.debug("Nostr relay not configured, skipping")
            return

        try:
            # Nostr NIP-01 event format
            event = ["EVENT", event_data]
            resp = requests.post(
                self.nostr_relay_url,
                json=event,
                timeout=10,
            )
            logger.info("Nostr event published: %s", resp.status_code)
        except Exception as e:
            logger.error("Nostr publish failed: %s", str(e))

    def send_session_message(self, recipient_id, message):
        """Send a message via Session messenger bot.

        Args:
            recipient_id: Session ID of the recipient
            message: Message text
        """
        if not self.session_bot_url:
            logger.debug("Session bot not configured, skipping")
            return

        try:
            resp = requests.post(
                f"{self.session_bot_url}/send",
                json={
                    "recipient": recipient_id,
                    "message": message,
                },
                timeout=10,
            )
            logger.info(
                "Session message sent: %s", resp.status_code
            )
        except Exception as e:
            logger.error("Session message failed: %s", str(e))
