"""
Minimal Flask microservice for the DevOps test.

Endpoints:
  GET /health   -> liveness/readiness probe (checks Postgres + Redis)
  GET /         -> demo endpoint that increments a Redis hit counter and
                   reads the current time from Postgres

Configuration is entirely via environment variables (12-factor):
  DATABASE_URL   e.g. postgresql://user:pass@db:5432/appdb
  REDIS_URL      e.g. redis://redis:6379/0
  APP_PORT       port to listen on (default 5000)
  LOG_DIR        directory for the app log file (default /var/log/app)
"""
import os
import logging
from datetime import datetime, timezone

from flask import Flask, jsonify
import psycopg2
import redis

APP_PORT = int(os.environ.get("APP_PORT", "5000"))
DATABASE_URL = os.environ.get("DATABASE_URL", "")
REDIS_URL = os.environ.get("REDIS_URL", "")
LOG_DIR = os.environ.get("LOG_DIR", "/var/log/app")

# ---------------------------------------------------------------------
# Logging: write to both stdout (for `docker logs`) and a file on the
# app-logs volume (required by the compose spec).
# ---------------------------------------------------------------------
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(LOG_DIR, "app.log")),
    ],
)
log = logging.getLogger("app")

app = Flask(__name__)


def get_db():
    return psycopg2.connect(DATABASE_URL, connect_timeout=3)


def get_redis():
    return redis.from_url(REDIS_URL, socket_connect_timeout=3)


@app.get("/health")
def health():
    """Return 200 only if BOTH Postgres and Redis are reachable."""
    status = {"status": "ok", "checks": {}}
    code = 200
    try:
        conn = get_db()
        conn.cursor().execute("SELECT 1")
        conn.close()
        status["checks"]["postgres"] = "ok"
    except Exception as exc:  # noqa: BLE001
        status["checks"]["postgres"] = f"error: {exc}"
        status["status"] = "degraded"
        code = 503
    try:
        get_redis().ping()
        status["checks"]["redis"] = "ok"
    except Exception as exc:  # noqa: BLE001
        status["checks"]["redis"] = f"error: {exc}"
        status["status"] = "degraded"
        code = 503
    return jsonify(status), code


@app.get("/")
def index():
    """Increment a Redis counter and read the DB time — proves both deps."""
    try:
        r = get_redis()
        hits = r.incr("hits")
    except Exception as exc:  # noqa: BLE001
        log.error("redis error: %s", exc)
        hits = None
    db_time = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT now()")
        db_time = cur.fetchone()[0].isoformat()
        conn.close()
    except Exception as exc:  # noqa: BLE001
        log.error("db error: %s", exc)
    return jsonify(
        {
            "message": "Hello from Flask microservice",
            "hits": hits,
            "db_time": db_time,
            "served_at": datetime.now(timezone.utc).isoformat(),
        }
    )


if __name__ == "__main__":
    log.info("starting app on port %s", APP_PORT)
    app.run(host="0.0.0.0", port=APP_PORT)
