"""Authentication routes for session and identity management.

Provides endpoints for:
- Session-based pseudonymous identity generation
- BIP39 mnemonic-based persistent identity
- BitID authentication
- Session verification
"""

import hashlib
import hmac
import logging
import secrets
import time

from flask import Blueprint, jsonify, request

logger = logging.getLogger(__name__)

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.route("/session", methods=["POST"])
def create_session():
    """Create a new pseudonymous session.

    No registration required. Generates a random nickname and
    session token for anonymous trading.

    Returns:
        JSON with session_token, nickname, and user details
    """
    from app.main import db
    from app.models.user import User

    user = User(
        nickname=User.generate_nickname(),
        session_token=User.generate_session_token(),
    )
    db.session.add(user)
    db.session.commit()

    logger.info("New session created: %s", user.nickname)

    return jsonify({
        "success": True,
        "user": user.to_dict(include_private=True),
    }), 201


@auth_bp.route("/session/verify", methods=["POST"])
def verify_session():
    """Verify an existing session token.

    Request body:
        session_token: The token to verify

    Returns:
        JSON with user details if valid
    """
    from app.models.user import User

    data = request.get_json(silent=True)
    if not data or "session_token" not in data:
        return jsonify({
            "success": False,
            "error": "session_token required",
        }), 400

    user = User.verify_session_token(data["session_token"])
    if not user:
        return jsonify({
            "success": False,
            "error": "Invalid session token",
        }), 401

    from app.main import db
    user.last_seen = time.time()
    db.session.commit()

    return jsonify({
        "success": True,
        "user": user.to_dict(include_private=True),
    })


@auth_bp.route("/mnemonic/generate", methods=["POST"])
def generate_mnemonic():
    """Generate a new 12-word BIP39 mnemonic for persistent identity.

    The mnemonic can be used to deterministically recover the
    user's identity and keypair.

    Returns:
        JSON with mnemonic phrase and derived public key
    """
    from mnemonic import Mnemonic

    mnemo = Mnemonic("english")
    phrase = mnemo.generate(strength=128)  # 12 words

    # Derive a deterministic keypair from the mnemonic
    seed = mnemo.to_seed(phrase)
    # Use first 32 bytes of seed as private key material
    private_key_material = seed[:32]

    import nacl.public

    private_key = nacl.public.PrivateKey(private_key_material)
    public_key = private_key.public_key

    import base64

    public_key_b64 = base64.b64encode(
        bytes(public_key)
    ).decode()

    return jsonify({
        "success": True,
        "mnemonic": phrase,
        "public_key": public_key_b64,
        "warning": (
            "Store this mnemonic securely. "
            "It cannot be recovered if lost."
        ),
    })


@auth_bp.route("/mnemonic/restore", methods=["POST"])
def restore_from_mnemonic():
    """Restore a persistent identity from a 12-word mnemonic.

    Request body:
        mnemonic: The 12-word BIP39 phrase

    Returns:
        JSON with session details and recovered identity
    """
    from mnemonic import Mnemonic

    data = request.get_json(silent=True)
    if not data or "mnemonic" not in data:
        return jsonify({
            "success": False,
            "error": "mnemonic required",
        }), 400

    phrase = data["mnemonic"].strip()
    mnemo = Mnemonic("english")

    if not mnemo.check(phrase):
        return jsonify({
            "success": False,
            "error": "Invalid mnemonic phrase",
        }), 400

    # Derive keypair from mnemonic
    seed = mnemo.to_seed(phrase)
    private_key_material = seed[:32]

    import nacl.public
    import base64

    private_key = nacl.public.PrivateKey(private_key_material)
    public_key = private_key.public_key
    public_key_b64 = base64.b64encode(
        bytes(public_key)
    ).decode()

    # Look up or create user by public key
    from app.main import db
    from app.models.user import User

    user = User.query.filter_by(
        public_key=public_key_b64
    ).first()

    if user:
        # Existing identity found - update session
        user.session_token = User.generate_session_token()
        user.last_seen = time.time()
        db.session.commit()
        logger.info(
            "Identity restored: %s", user.nickname
        )
    else:
        # New persistent identity
        user = User(
            nickname=User.generate_nickname(),
            session_token=User.generate_session_token(),
            public_key=public_key_b64,
        )
        db.session.add(user)
        db.session.commit()
        logger.info(
            "New persistent identity created: %s",
            user.nickname,
        )

    return jsonify({
        "success": True,
        "user": user.to_dict(include_private=True),
        "restored": user.total_trades > 0,
    })


@auth_bp.route("/bitid/challenge", methods=["GET"])
def bitid_challenge():
    """Generate a BitID authentication challenge.

    Returns a challenge string that the user signs with their
    private key to prove identity ownership.

    Returns:
        JSON with challenge string and expiry
    """
    challenge = secrets.token_hex(32)
    expires = time.time() + 300  # 5 minutes

    # Create HMAC of challenge for server-side verification
    from flask import current_app

    mac = hmac.new(
        current_app.config["SECRET_KEY"].encode(),
        f"{challenge}:{expires}".encode(),
        hashlib.sha256,
    ).hexdigest()

    return jsonify({
        "success": True,
        "challenge": challenge,
        "expires": expires,
        "mac": mac,
    })


@auth_bp.route("/bitid/verify", methods=["POST"])
def bitid_verify():
    """Verify a BitID authentication response.

    Request body:
        challenge: The original challenge string
        signature: The signed challenge
        public_key: The signer's public key
        expires: Challenge expiry timestamp
        mac: HMAC from the challenge response

    Returns:
        JSON with session details if authentication succeeds
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            "success": False,
            "error": "Request body required",
        }), 400

    required = [
        "challenge", "signature", "public_key", "expires", "mac",
    ]
    for field in required:
        if field not in data:
            return jsonify({
                "success": False,
                "error": f"{field} required",
            }), 400

    # Verify expiry
    if time.time() > data["expires"]:
        return jsonify({
            "success": False,
            "error": "Challenge expired",
        }), 401

    # Verify HMAC
    from flask import current_app

    expected_mac = hmac.new(
        current_app.config["SECRET_KEY"].encode(),
        f"{data['challenge']}:{data['expires']}".encode(),
        hashlib.sha256,
    ).hexdigest()

    if not hmac.compare_digest(expected_mac, data["mac"]):
        return jsonify({
            "success": False,
            "error": "Invalid challenge MAC",
        }), 401

    # Verify signature
    import base64
    import nacl.public
    import nacl.signing

    try:
        public_key_bytes = base64.b64decode(data["public_key"])
        verify_key = nacl.signing.VerifyKey(public_key_bytes)
        signature_bytes = base64.b64decode(data["signature"])
        verify_key.verify(
            data["challenge"].encode(), signature_bytes
        )
    except Exception:
        return jsonify({
            "success": False,
            "error": "Invalid signature",
        }), 401

    # Authenticate user
    from app.main import db
    from app.models.user import User

    public_key_b64 = data["public_key"]
    user = User.query.filter_by(
        public_key=public_key_b64
    ).first()

    if user:
        user.session_token = User.generate_session_token()
        user.last_seen = time.time()
    else:
        user = User(
            nickname=User.generate_nickname(),
            session_token=User.generate_session_token(),
            public_key=public_key_b64,
        )
        db.session.add(user)

    db.session.commit()

    return jsonify({
        "success": True,
        "user": user.to_dict(include_private=True),
    })


def get_current_user():
    """Helper to get the current authenticated user from request.

    Checks the Authorization header for a valid session token.

    Returns:
        User instance or None
    """
    from app.models.user import User

    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        token = auth[7:]
        return User.verify_session_token(token)
    return None


def require_auth(f):
    """Decorator to require authentication on a route.

    Uses the Authorization: Bearer <session_token> header.
    """
    from functools import wraps

    @wraps(f)
    def decorated(*args, **kwargs):
        user = get_current_user()
        if not user:
            return jsonify({
                "success": False,
                "error": "Authentication required",
            }), 401
        return f(user, *args, **kwargs)

    return decorated
