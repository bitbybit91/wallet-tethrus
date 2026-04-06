"""Tests for the reputation service."""

from unittest.mock import MagicMock

from app.services.reputation import ReputationService


class TestReputationCalculation:
    """Test trust score calculation."""

    def test_zero_trades(self):
        """Test score with no trades."""
        user = MagicMock()
        user.total_trades = 0

        score = ReputationService.calculate_trust_score(user)
        assert score == 0.0

    def test_perfect_trader(self):
        """Test score with all successful trades."""
        user = MagicMock()
        user.total_trades = 50
        user.successful_trades = 50
        user.disputed_trades = 0
        user.avg_response_time = 5  # 5 minutes

        score = ReputationService.calculate_trust_score(user)
        assert score > 80  # Should be high

    def test_bad_trader(self):
        """Test score with many disputes and slow response."""
        user = MagicMock()
        user.total_trades = 10
        user.successful_trades = 3
        user.disputed_trades = 7
        user.avg_response_time = 120  # Very slow

        score = ReputationService.calculate_trust_score(user)
        assert score < 40  # Should be low

    def test_score_range(self):
        """Test that score is always between 0 and 100."""
        for successful in range(0, 101, 10):
            user = MagicMock()
            user.total_trades = 100
            user.successful_trades = successful
            user.disputed_trades = 100 - successful
            user.avg_response_time = 30

            score = ReputationService.calculate_trust_score(
                user
            )
            assert 0 <= score <= 100

    def test_reputation_summary(self):
        """Test getting reputation summary."""
        user = MagicMock()
        user.id = 1
        user.nickname = "TestTrader"
        user.trust_score = 85.5
        user.total_trades = 42
        user.successful_trades = 40
        user.success_rate = 95.2
        user.disputed_trades = 2
        user.avg_response_time = 12.3
        user.created_at = 1700000000.0

        summary = ReputationService.get_reputation_summary(
            user
        )

        assert summary["user_id"] == 1
        assert summary["nickname"] == "TestTrader"
        assert summary["trust_score"] == 85.5
        assert summary["total_trades"] == 42
        assert summary["success_rate"] == 95.2
