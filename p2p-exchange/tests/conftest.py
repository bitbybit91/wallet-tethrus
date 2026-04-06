"""Test configuration and fixtures for the P2P Exchange."""

import os
import sys

import pytest

# Add the project root to the path
sys.path.insert(
    0, os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
)


@pytest.fixture
def app():
    """Create a Flask application for testing."""
    from app.main import create_app

    app = create_app("testing")
    yield app


@pytest.fixture
def client(app):
    """Create a test client."""
    return app.test_client()


@pytest.fixture
def db(app):
    """Create a database instance for testing."""
    from app.main import db as _db

    with app.app_context():
        _db.create_all()
        yield _db
        _db.session.rollback()
        _db.drop_all()


@pytest.fixture
def session_token(client):
    """Create a user session and return the token."""
    resp = client.post("/api/auth/session")
    data = resp.get_json()
    return data["user"]["session_token"]


@pytest.fixture
def auth_headers(session_token):
    """Return authorization headers for API requests."""
    return {"Authorization": f"Bearer {session_token}"}


@pytest.fixture
def second_session_token(client):
    """Create a second user session for multi-party tests."""
    resp = client.post("/api/auth/session")
    data = resp.get_json()
    return data["user"]["session_token"]


@pytest.fixture
def second_auth_headers(second_session_token):
    """Return authorization headers for the second user."""
    return {"Authorization": f"Bearer {second_session_token}"}
