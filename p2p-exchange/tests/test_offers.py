"""Tests for offer management."""

import json


class TestOffersList:
    """Test offer listing and filtering."""

    def test_list_empty_offers(self, client, db):
        """Test listing offers when none exist."""
        resp = client.get("/api/offers")
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["success"] is True
        assert len(data["offers"]) == 0

    def test_list_offers_with_data(
        self, client, db, auth_headers
    ):
        """Test listing offers after creating some."""
        # Create an offer
        client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Bank Transfer"],
            },
        )

        resp = client.get("/api/offers")
        data = resp.get_json()

        assert resp.status_code == 200
        assert len(data["offers"]) == 1

    def test_filter_by_type(
        self, client, db, auth_headers
    ):
        """Test filtering offers by type."""
        # Create buy and sell offers
        for otype in ("buy", "sell"):
            client.post(
                "/api/offers",
                headers=auth_headers,
                json={
                    "offer_type": otype,
                    "amount_min": 10,
                    "amount_max": 1000,
                    "price_per_usdt": 1.02,
                    "currency": "USD",
                    "payment_methods": ["Cash"],
                },
            )

        resp = client.get("/api/offers?type=sell")
        data = resp.get_json()

        assert resp.status_code == 200
        for offer in data["offers"]:
            assert offer["offer_type"] == "sell"


class TestOfferCreate:
    """Test offer creation."""

    def test_create_sell_offer(
        self, client, db, auth_headers
    ):
        """Test creating a sell offer."""
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": [
                    "Bank Transfer", "PayPal"
                ],
                "terms": "Fast payment required",
                "location": "New York, US",
            },
        )
        data = resp.get_json()

        assert resp.status_code == 201
        assert data["success"] is True
        assert data["offer"]["offer_type"] == "sell"
        assert data["offer"]["amount_min"] == 10
        assert data["offer"]["amount_max"] == 1000
        assert data["offer"]["currency"] == "USD"

    def test_create_without_auth(self, client, db):
        """Test that creating an offer requires authentication."""
        resp = client.post(
            "/api/offers",
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )

        assert resp.status_code == 401

    def test_create_invalid_type(
        self, client, db, auth_headers
    ):
        """Test that invalid offer type is rejected."""
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "invalid",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )

        assert resp.status_code == 400

    def test_create_negative_amount(
        self, client, db, auth_headers
    ):
        """Test that negative amounts are rejected."""
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": -10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )

        assert resp.status_code == 400

    def test_create_min_exceeds_max(
        self, client, db, auth_headers
    ):
        """Test that min amount exceeding max is rejected."""
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 1000,
                "amount_max": 10,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )

        assert resp.status_code == 400


class TestOfferUpdate:
    """Test offer update and deletion."""

    def test_update_own_offer(
        self, client, db, auth_headers
    ):
        """Test updating your own offer."""
        # Create offer
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )
        offer_id = resp.get_json()["offer"]["id"]

        # Update
        resp = client.put(
            f"/api/offers/{offer_id}",
            headers=auth_headers,
            json={"price_per_usdt": 1.05},
        )
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["offer"]["price_per_usdt"] == 1.05

    def test_delete_own_offer(
        self, client, db, auth_headers
    ):
        """Test deleting your own offer."""
        # Create offer
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )
        offer_id = resp.get_json()["offer"]["id"]

        # Delete
        resp = client.delete(
            f"/api/offers/{offer_id}",
            headers=auth_headers,
        )

        assert resp.status_code == 200

    def test_cannot_update_others_offer(
        self, client, db, auth_headers, second_auth_headers
    ):
        """Test that you cannot update another user's offer."""
        # Create offer as first user
        resp = client.post(
            "/api/offers",
            headers=auth_headers,
            json={
                "offer_type": "sell",
                "amount_min": 10,
                "amount_max": 1000,
                "price_per_usdt": 1.02,
                "currency": "USD",
                "payment_methods": ["Cash"],
            },
        )
        offer_id = resp.get_json()["offer"]["id"]

        # Try to update as second user
        resp = client.put(
            f"/api/offers/{offer_id}",
            headers=second_auth_headers,
            json={"price_per_usdt": 999},
        )

        assert resp.status_code == 403
