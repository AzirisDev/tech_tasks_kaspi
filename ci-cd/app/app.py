"""
Flask microservice with PostgreSQL + Redis (CI/CD-testable version).

Endpoints:
  GET /health  -> 200 if Postgres + Redis reachable, else 503
  GET /        -> increments a Redis counter, reads DB time
  GET /version -> returns the app version (no external deps; easy to test)

Connection factories are module-level so tests can monkeypatch them
without a live database or cache.
"""
import os
import logging
from datetime import datetime, timezone

from flask import Flask, jsonify

APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_PORT = int(os.environ.get("APP_PORT", "5000"))
DATABASE_URL = os.environ.get("DATABASE_URL", "")
REDIS_URL = os.environ.get("REDIS_URL", "")
LOG_DIR = os.environ.get("LOG_DIR", "/var/log/app")
APP_ENV = os.environ.get("APP_ENV", "production")

# Logging to stdout always; to file only when the dir is writable.
handlers = [logging.StreamHandler()]
try:
    os.makedirs(LOG_DIR, exist_ok=True)
    handlers.append(logging.FileHandler(os.path.join(LOG_DIR, "app.log")))
except OSError:
    pass
logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=handlers,
)
log = logging.getLogger("app")


def get_db_connection():
    """Return a psycopg2 connection. Imported lazily so the module loads
    (and unit tests run) even if psycopg2 isn't installed."""
    import psycopg2
    return psycopg2.connect(DATABASE_URL, connect_timeout=3)


def get_redis_client():
    """Return a Redis client. Imported lazily for the same reason."""
    import redis
    return redis.from_url(REDIS_URL, socket_connect_timeout=3)


def check_postgres():
    """True if a trivial query succeeds."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.fetchone()
        return True
    finally:
        conn.close()


def check_redis():
    """True if PING succeeds."""
    return bool(get_redis_client().ping())


def create_app():
    app = Flask(__name__)

    @app.get("/health")
    def health():
        checks, ok = {}, True
        try:
            check_postgres()
            checks["postgres"] = "ok"
        except Exception as exc:  # noqa: BLE001
            checks["postgres"] = f"error: {exc}"
            ok = False
        try:
            check_redis()
            checks["redis"] = "ok"
        except Exception as exc:  # noqa: BLE001
            checks["redis"] = f"error: {exc}"
            ok = False
        status = "ok" if ok else "degraded"
        code = 200 if ok else 503
        return jsonify({"status": status, "checks": checks}), code

    @app.get("/version")
    def version():
        return jsonify({"version": APP_VERSION, "env": APP_ENV})

    @app.get("/")
    def index():
        hits = None
        try:
            hits = get_redis_client().incr("hits")
        except Exception as exc:  # noqa: BLE001
            log.error("redis error: %s", exc)
        db_time = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("SELECT now()")
            db_time = cur.fetchone()[0].isoformat()
            conn.close()
        except Exception as exc:  # noqa: BLE001
            log.error("db error: %s", exc)
        return jsonify({
            "message": "Hello from Flask microservice",
            "hits": hits,
            "db_time": db_time,
            "served_at": datetime.now(timezone.utc).isoformat(),
        })

    return app


app = create_app()

if __name__ == "__main__":
    log.info("starting app on port %s", APP_PORT)
    app.run(host="0.0.0.0", port=APP_PORT)
