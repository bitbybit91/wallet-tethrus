"""Trader reputation service.

Calculates and manages trader reputation scores based on
trade history, response times, and dispute rates.
"""

import logging
import time

logger = logging.getLogger(__name__)


class ReputationService:
    """Service for managing trader reputation and trust scores.

    Trust score is calculated from:
    - Trade completion rate (weight: 40%)
    - Total trade volume (weight: 30%)
    - Average response time (weight: 20%)
    - Dispute rate (weight: 10%, inverse)
    """

    # Weight factors for trust score calculation
    WEIGHT_COMPLETION = 0.40
    WEIGHT_VOLUME = 0.30
    WEIGHT_RESPONSE = 0.20
    WEIGHT_DISPUTES = 0.10

    # Thresholds
    MAX_RESPONSE_TIME_MINUTES = 60  # Considered "slow" above this
    VOLUME_BENCHMARK = 100  # Number of trades for max volume score

    @staticmethod
    def calculate_trust_score(user):
        """Calculate the trust score for a user.

        Args:
            user: User model instance

        Returns:
            float trust score between 0.0 and 100.0
        """
        if user.total_trades == 0:
            return 0.0

        # Completion rate score (0-100)
        completion_score = (
            (user.successful_trades / user.total_trades) * 100
        )

        # Volume score (0-100, capped at benchmark)
        volume_score = min(
            (user.total_trades / ReputationService.VOLUME_BENCHMARK)
            * 100,
            100,
        )

        # Response time score (0-100, lower is better)
        avg_response = user.avg_response_time
        if avg_response <= 0:
            response_score = 100.0
        elif (
            avg_response
            >= ReputationService.MAX_RESPONSE_TIME_MINUTES
        ):
            response_score = 0.0
        else:
            response_score = (
                1
                - (
                    avg_response
                    / ReputationService.MAX_RESPONSE_TIME_MINUTES
                )
            ) * 100

        # Dispute rate score (0-100, inverse - fewer disputes = better)
        dispute_rate = user.disputed_trades / user.total_trades
        dispute_score = (1 - dispute_rate) * 100

        # Weighted total
        trust_score = (
            completion_score * ReputationService.WEIGHT_COMPLETION
            + volume_score * ReputationService.WEIGHT_VOLUME
            + response_score * ReputationService.WEIGHT_RESPONSE
            + dispute_score * ReputationService.WEIGHT_DISPUTES
        )

        return round(max(0.0, min(100.0, trust_score)), 1)

    @staticmethod
    def update_after_trade(user, trade, was_successful):
        """Update user reputation after a trade completes.

        Args:
            user: User model instance
            trade: Trade model instance
            was_successful: bool indicating trade outcome
        """
        from app.main import db

        user.total_trades += 1

        if was_successful:
            user.successful_trades += 1

        # Calculate response time for this trade
        if trade.created_at and trade.completed_at:
            response_minutes = (
                (trade.completed_at - trade.created_at) / 60
            )
            user.total_response_time += response_minutes

        if trade.status == "disputed":
            user.disputed_trades += 1

        # Recalculate trust score
        user.trust_score = ReputationService.calculate_trust_score(
            user
        )
        db.session.commit()

        logger.info(
            "Updated reputation for user %s: score=%.1f",
            user.nickname,
            user.trust_score,
        )

    @staticmethod
    def get_reputation_summary(user):
        """Get a formatted reputation summary for a user.

        Args:
            user: User model instance

        Returns:
            dict with reputation details
        """
        return {
            "user_id": user.id,
            "nickname": user.nickname,
            "trust_score": user.trust_score,
            "total_trades": user.total_trades,
            "successful_trades": user.successful_trades,
            "success_rate": user.success_rate,
            "disputed_trades": user.disputed_trades,
            "avg_response_time_minutes": user.avg_response_time,
            "member_since": user.created_at,
        }
