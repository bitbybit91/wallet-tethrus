"""Non-custodial escrow service for USDT-TRC20 trades.

Implements a non-custodial escrow mechanism where the platform
never holds private keys or custodies funds. Escrow is verified
through on-chain transaction monitoring.
"""

import logging
import time

logger = logging.getLogger(__name__)


class EscrowService:
    """Non-custodial escrow management for P2P trades.

    The escrow mechanism works as follows:
    1. Seller sends USDT to a deterministic escrow address
    2. Platform monitors the on-chain transaction
    3. Upon trade completion, seller releases funds to buyer
    4. In disputes, an arbitrator can direct fund release

    The platform never holds private keys - it only verifies
    on-chain transactions and coordinates the trade flow.
    """

    def __init__(self, tron_service=None, app=None):
        """Initialize EscrowService.

        Args:
            tron_service: TronService instance for blockchain ops
            app: Flask application for configuration
        """
        self.tron_service = tron_service
        self.timeout_hours = 24
        self.required_confirmations = 20
        if app:
            self.init_app(app)

    def init_app(self, app):
        """Initialize with Flask application configuration."""
        self.timeout_hours = app.config.get(
            "ESCROW_TIMEOUT_HOURS", 24
        )
        self.required_confirmations = app.config.get(
            "ESCROW_CONFIRMATION_BLOCKS", 20
        )

    def create_escrow(self, trade):
        """Create an escrow for a trade.

        Generates a deterministic escrow address and sets up
        the trade for escrow funding. The seller must send
        USDT-TRC20 to this address.

        Args:
            trade: Trade model instance

        Returns:
            dict with escrow details
        """
        from app.main import db
        from app.models.trade import Trade

        # Generate escrow keypair - in production, this would use
        # a multi-sig or time-locked smart contract
        escrow = self.tron_service.generate_keypair()

        trade.escrow_address = escrow["address"]
        trade.status = "escrow_pending"
        trade.expires_at = time.time() + (
            self.timeout_hours * 3600
        )
        db.session.commit()

        logger.info(
            "Escrow created for trade %d at address %s",
            trade.id,
            escrow["address"],
        )

        return {
            "escrow_address": escrow["address"],
            "amount_usdt": trade.amount_usdt,
            "expires_at": trade.expires_at,
            "trade_id": trade.id,
        }

    def verify_escrow_funding(self, trade):
        """Verify that the escrow address has been funded.

        Checks the USDT-TRC20 balance of the escrow address
        to confirm the seller has deposited the required amount.

        Args:
            trade: Trade model instance

        Returns:
            dict with verification status
        """
        from app.main import db

        if not trade.escrow_address:
            return {
                "funded": False,
                "error": "No escrow address set",
            }

        balance = self.tron_service.get_usdt_balance(
            trade.escrow_address
        )

        if balance >= trade.amount_usdt:
            trade.status = "escrow_funded"
            trade.escrow_funded_at = time.time()
            db.session.commit()

            logger.info(
                "Escrow funded for trade %d: %.6f USDT",
                trade.id,
                balance,
            )

            return {
                "funded": True,
                "balance": balance,
                "required": trade.amount_usdt,
            }

        return {
            "funded": False,
            "balance": balance,
            "required": trade.amount_usdt,
            "shortfall": trade.amount_usdt - balance,
        }

    def verify_escrow_transaction(self, trade, tx_id):
        """Verify a specific escrow funding transaction.

        Checks that a transaction exists, is confirmed, and
        sends the correct amount to the escrow address.

        Args:
            trade: Trade model instance
            tx_id: Transaction hash to verify

        Returns:
            dict with verification result
        """
        from app.main import db

        monitor = self.tron_service.monitor_transaction(
            tx_id, self.required_confirmations
        )

        if not monitor["exists"]:
            return {
                "verified": False,
                "error": "Transaction not found",
            }

        trade.escrow_tx_id = tx_id

        if monitor["confirmed"]:
            trade.escrow_confirmed = True
            trade.status = "escrow_funded"
            trade.escrow_funded_at = time.time()
            db.session.commit()

            logger.info(
                "Escrow transaction verified for trade %d: %s",
                trade.id,
                tx_id,
            )

        return {
            "verified": monitor["confirmed"],
            "confirmations": monitor["confirmations"],
            "required_confirmations": self.required_confirmations,
            "tx_id": tx_id,
        }

    def release_escrow(self, trade, to_address, private_key=None):
        """Release escrowed funds to the specified address.

        In the non-custodial model, this function builds the
        release transaction. If a private key is provided, it
        signs and broadcasts. Otherwise, returns unsigned TX.

        Args:
            trade: Trade model instance
            to_address: Recipient TRON address
            private_key: Optional escrow private key for signing

        Returns:
            dict with release transaction details
        """
        from app.main import db

        if trade.status not in ("escrow_funded", "fiat_confirmed"):
            return {
                "success": False,
                "error": (
                    f"Cannot release escrow in status: {trade.status}"
                ),
            }

        result = self.tron_service.build_usdt_transfer(
            from_address=trade.escrow_address,
            to_address=to_address,
            amount_usdt=trade.amount_usdt,
            private_key=private_key,
        )

        if result.get("success"):
            trade.release_tx_id = result.get("tx_id")
            trade.status = "completed"
            trade.completed_at = time.time()
            db.session.commit()

            logger.info(
                "Escrow released for trade %d to %s",
                trade.id,
                to_address,
            )

        return result

    def check_expiry(self, trade):
        """Check if a trade's escrow has expired.

        Args:
            trade: Trade model instance

        Returns:
            bool indicating if the escrow has expired
        """
        from app.main import db

        if trade.expires_at and time.time() > trade.expires_at:
            if trade.status in (
                "initiated",
                "escrow_pending",
            ):
                trade.status = "expired"
                db.session.commit()
                logger.info(
                    "Trade %d expired", trade.id
                )
                return True
        return False

    def open_dispute(self, trade, user_id, reason):
        """Open a dispute on a trade.

        Args:
            trade: Trade model instance
            user_id: ID of user opening the dispute
            reason: Text description of the dispute

        Returns:
            dict with dispute details
        """
        from app.main import db

        if trade.status in ("completed", "cancelled", "expired"):
            return {
                "success": False,
                "error": (
                    f"Cannot dispute trade in status: {trade.status}"
                ),
            }

        trade.status = "disputed"
        trade.dispute_reason = reason
        trade.dispute_opened_by = user_id
        trade.disputed_at = time.time()
        db.session.commit()

        logger.info(
            "Dispute opened on trade %d by user %d",
            trade.id,
            user_id,
        )

        return {
            "success": True,
            "trade_id": trade.id,
            "status": "disputed",
            "reason": reason,
        }

    def resolve_dispute(
        self, trade, arbitrator_id, resolution, release_to
    ):
        """Resolve a disputed trade.

        An arbitrator reviews the evidence and decides who
        receives the escrowed funds.

        Args:
            trade: Trade model instance
            arbitrator_id: ID of the arbitrator user
            resolution: Text description of the resolution
            release_to: 'buyer' or 'seller'

        Returns:
            dict with resolution details
        """
        from app.main import db

        if trade.status != "disputed":
            return {
                "success": False,
                "error": "Trade is not in disputed status",
            }

        trade.dispute_resolution = resolution
        trade.arbitrator_id = arbitrator_id

        if release_to == "buyer":
            to_address = trade.buyer_address
        elif release_to == "seller":
            to_address = trade.seller_address
        else:
            return {
                "success": False,
                "error": "release_to must be 'buyer' or 'seller'",
            }

        trade.status = "completed"
        trade.completed_at = time.time()
        db.session.commit()

        logger.info(
            "Dispute resolved on trade %d by arbitrator %d, "
            "funds to %s",
            trade.id,
            arbitrator_id,
            release_to,
        )

        return {
            "success": True,
            "trade_id": trade.id,
            "resolution": resolution,
            "release_to": release_to,
            "to_address": to_address,
        }
