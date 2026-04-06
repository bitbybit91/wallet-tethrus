"""P2P Exchange application entry point.

Initializes the Flask application with all services, routes,
database, and WebSocket support.
"""

import logging
import os

from flask import Flask, jsonify, render_template, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_migrate import Migrate
from flask_socketio import SocketIO, join_room, leave_room
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect

from app.config import config_by_name

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
socketio = SocketIO()
csrf = CSRFProtect()
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri="memory://",
)

# Initialize services (will be configured with app)
tron_service = None
escrow_service = None
notification_service = None


def create_app(config_name=None):
    """Create and configure the Flask application.

    Args:
        config_name: Configuration name ('development', 'testing',
                     'production'). Defaults to FLASK_ENV env var.

    Returns:
        Configured Flask application instance
    """
    global tron_service, escrow_service, notification_service

    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "production")

    app = Flask(
        __name__,
        static_folder="static",
        template_folder="templates",
    )
    app.config.from_object(config_by_name[config_name])

    # Configure logging
    log_level = getattr(
        logging, app.config.get("LOG_LEVEL", "INFO")
    )
    logging.basicConfig(
        level=log_level,
        format=(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        ),
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(
                app.config.get("LOG_FILE", "p2p_exchange.log")
            ),
        ],
    )
    logger = logging.getLogger(__name__)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    socketio.init_app(
        app,
        cors_allowed_origins="*",
        async_mode="gevent",
        logger=False,
    )
    csrf.init_app(app)
    limiter.init_app(app)

    # Initialize services
    from app.services.escrow import EscrowService
    from app.services.notifications import NotificationService
    from app.services.tron import TronService

    tron_service = TronService(app)
    escrow_service = EscrowService(tron_service, app)
    notification_service = NotificationService(app)

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.chat import chat_bp
    from app.routes.offers import offers_bp
    from app.routes.trades import trades_bp
    from app.routes.wallet import wallet_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(offers_bp)
    app.register_blueprint(trades_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(wallet_bp)

    # Exempt API blueprints from CSRF (they use token auth)
    csrf.exempt(auth_bp)
    csrf.exempt(offers_bp)
    csrf.exempt(trades_bp)
    csrf.exempt(chat_bp)
    csrf.exempt(wallet_bp)

    # Security headers middleware
    @app.after_request
    def set_security_headers(response):
        """Add security headers to all responses."""
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Permissions-Policy"] = (
            "geolocation=(), camera=(), microphone=()"
        )
        # CSP - strict, no external resources (Tor-friendly)
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data:; "
            "connect-src 'self' ws: wss:; "
            "font-src 'self'; "
            "frame-ancestors 'none'"
        )
        if not app.config.get("TOR_ENABLED"):
            response.headers[
                "Strict-Transport-Security"
            ] = "max-age=31536000; includeSubDomains"
        return response

    # Frontend routes
    @app.route("/")
    def index():
        """Serve the main page."""
        return render_template("index.html")

    @app.route("/offers")
    def offers_page():
        """Serve the offers listing page."""
        return render_template("offers.html")

    @app.route("/trade/<int:trade_id>")
    def trade_page(trade_id):
        """Serve the trade detail page."""
        return render_template(
            "trade.html", trade_id=trade_id
        )

    @app.route("/chat/<int:trade_id>")
    def chat_page(trade_id):
        """Serve the encrypted chat page."""
        return render_template(
            "chat.html", trade_id=trade_id
        )

    # Health check endpoint
    @app.route("/api/health")
    def health():
        """Application health check."""
        return jsonify({
            "status": "healthy",
            "version": "1.0.0",
        })

    # Error handlers
    @app.errorhandler(404)
    def not_found(e):
        if request.path.startswith("/api/"):
            return jsonify({
                "success": False,
                "error": "Not found",
            }), 404
        return render_template("index.html"), 404

    @app.errorhandler(429)
    def rate_limited(e):
        return jsonify({
            "success": False,
            "error": "Rate limit exceeded",
        }), 429

    @app.errorhandler(500)
    def internal_error(e):
        logger.error("Internal error: %s", str(e))
        return jsonify({
            "success": False,
            "error": "Internal server error",
        }), 500

    # Create database tables
    with app.app_context():
        # Import models to register them
        from app.models.message import Message  # noqa: F401
        from app.models.offer import Offer  # noqa: F401
        from app.models.trade import Trade  # noqa: F401
        from app.models.user import User  # noqa: F401

        db.create_all()

    logger.info("P2P Exchange application initialized")
    return app


# WebSocket event handlers
@socketio.on("join_trade")
def handle_join_trade(data):
    """Join a trade chat room for real-time updates."""
    trade_id = data.get("trade_id")
    if trade_id:
        join_room(f"trade_{trade_id}")


@socketio.on("leave_trade")
def handle_leave_trade(data):
    """Leave a trade chat room."""
    trade_id = data.get("trade_id")
    if trade_id:
        leave_room(f"trade_{trade_id}")


if __name__ == "__main__":
    app = create_app()
    socketio.run(app, host="0.0.0.0", port=5000, debug=True)
