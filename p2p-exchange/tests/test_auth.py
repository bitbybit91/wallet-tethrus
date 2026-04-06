"""Tests for the authentication system."""

import json


class TestSession:
    """Test session creation and verification."""

    def test_create_session(self, client, db):
        """Test creating a new anonymous session."""
        resp = client.post("/api/auth/session")
        data = resp.get_json()

        assert resp.status_code == 201
        assert data["success"] is True
        assert "session_token" in data["user"]
        assert "nickname" in data["user"]
        assert len(data["user"]["session_token"]) == 128

    def test_verify_valid_session(self, client, db):
        """Test verifying a valid session token."""
        # Create session
        resp = client.post("/api/auth/session")
        token = resp.get_json()["user"]["session_token"]

        # Verify
        resp = client.post(
            "/api/auth/session/verify",
            json={"session_token": token},
        )
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["success"] is True

    def test_verify_invalid_session(self, client, db):
        """Test verifying an invalid session token."""
        resp = client.post(
            "/api/auth/session/verify",
            json={"session_token": "x" * 128},
        )
        data = resp.get_json()

        assert resp.status_code == 401
        assert data["success"] is False

    def test_verify_missing_token(self, client, db):
        """Test verification without a token."""
        resp = client.post(
            "/api/auth/session/verify",
            json={},
        )
        data = resp.get_json()

        assert resp.status_code == 400


class TestMnemonic:
    """Test BIP39 mnemonic identity management."""

    def test_generate_mnemonic(self, client, db):
        """Test generating a new mnemonic phrase."""
        resp = client.post("/api/auth/mnemonic/generate")
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["success"] is True
        assert "mnemonic" in data
        words = data["mnemonic"].split()
        assert len(words) == 12
        assert "public_key" in data

    def test_restore_from_mnemonic(self, client, db):
        """Test restoring identity from a mnemonic."""
        # Generate
        resp = client.post("/api/auth/mnemonic/generate")
        mnemonic = resp.get_json()["mnemonic"]

        # Restore
        resp = client.post(
            "/api/auth/mnemonic/restore",
            json={"mnemonic": mnemonic},
        )
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["success"] is True
        assert "session_token" in data["user"]

    def test_restore_same_identity(self, client, db):
        """Test that restoring the same mnemonic gives same identity."""
        resp = client.post("/api/auth/mnemonic/generate")
        mnemonic = resp.get_json()["mnemonic"]

        # First restore
        resp1 = client.post(
            "/api/auth/mnemonic/restore",
            json={"mnemonic": mnemonic},
        )
        nickname1 = resp1.get_json()["user"]["nickname"]

        # Second restore
        resp2 = client.post(
            "/api/auth/mnemonic/restore",
            json={"mnemonic": mnemonic},
        )
        nickname2 = resp2.get_json()["user"]["nickname"]

        # Same identity
        assert nickname1 == nickname2

    def test_invalid_mnemonic(self, client, db):
        """Test restoring with invalid mnemonic fails."""
        resp = client.post(
            "/api/auth/mnemonic/restore",
            json={"mnemonic": "invalid words here"},
        )
        data = resp.get_json()

        assert resp.status_code == 400
        assert data["success"] is False


class TestBitID:
    """Test BitID authentication."""

    def test_get_challenge(self, client, db):
        """Test getting a BitID challenge."""
        resp = client.get("/api/auth/bitid/challenge")
        data = resp.get_json()

        assert resp.status_code == 200
        assert data["success"] is True
        assert "challenge" in data
        assert "expires" in data
        assert "mac" in data
