"""
Flask microservice with Prometheus metrics + structured JSON logging.

Adds on top of the base service:
  - /metrics endpoint (Prometheus exposition format)
  - http_requests_total{method,endpoint,status}
  - http_request_duration_seconds histogram
  - db_connection_errors_total counter
  - JSON logs with: timestamp, level, message, service, pod_name, request_id
"""
import os
import time
import uuid
import json
import logging
from datetime import datetime, timezone

from flask import Flask, jsonify, request, g, Response
from prometheus_client import (
    Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST,
)

SERVICE_NAME = os.environ.get("SERVICE_NAME", "flask-app")
POD_NAME = os.environ.get("POD_NAME", os.uname().nodename)
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")

# --------------------------------------------------------------------- #
# Structured JSON logging
# --------------------------------------------------------------------- #
class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "service": SERVICE_NAME,
            "pod_name": POD_NAME,
            "request_id": getattr(record, "request_id", None),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"), handlers=[handler])
log = logging.getLogger(SERVICE_NAME)

# --------------------------------------------------------------------- #
# Prometheus metrics
# --------------------------------------------------------------------- #
REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request duration in seconds",
    ["method", "endpoint"],
)
DB_ERRORS = Counter(
    "db_connection_errors_total", "Total database connection errors",
)
INFO = Gauge("app_info", "App info", ["version", "service"])
INFO.labels(version=APP_VERSION, service=SERVICE_NAME).set(1)


def create_app():
    app = Flask(__name__)

    @app.before_request
    def _start_timer():
        g.start_time = time.time()
        g.request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

    @app.after_request
    def _record_metrics(response):
        # Don't instrument the /metrics scrape itself.
        endpoint = request.path
        if endpoint != "/metrics":
            latency = time.time() - getattr(g, "start_time", time.time())
            REQUEST_LATENCY.labels(request.method, endpoint).observe(latency)
            REQUEST_COUNT.labels(request.method, endpoint, response.status_code).inc()
            log.info(
                "%s %s -> %s (%.3fs)",
                request.method, endpoint, response.status_code, latency,
                extra={"request_id": getattr(g, "request_id", None)},
            )
        response.headers["X-Request-ID"] = getattr(g, "request_id", "")
        return response

    @app.get("/metrics")
    def metrics():
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"}), 200

    @app.get("/version")
    def version():
        return jsonify({"version": APP_VERSION, "service": SERVICE_NAME})

    @app.get("/")
    def index():
        return jsonify({
            "message": "Hello from instrumented Flask microservice",
            "served_at": datetime.now(timezone.utc).isoformat(),
        })

    return app


app = create_app()

if __name__ == "__main__":
    log.info("starting instrumented app")
    app.run(host="0.0.0.0", port=int(os.environ.get("APP_PORT", "5000")))
