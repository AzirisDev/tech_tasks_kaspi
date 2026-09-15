#  Multi-stage Dockerfile for the Flask microservice
#  Target final image size: < 200 MB (python:3.12-slim base)

# ---------- Stage 1: builder ----------------------------------------
# Installs dependencies into an isolated prefix so the final image
# carries only the built packages, not build tooling or caches.
FROM python:3.12-slim AS builder

# Build deps for psycopg2-binary are not needed (binary wheel), but we
# keep gcc available in case a source wheel is ever required. Removed
# from the final image entirely because this stage is discarded.
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build
COPY requirements.txt .

# Install into /install so we can copy just that tree into the runtime.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: production -------------------------------------
FROM python:3.12-slim AS production

# ---- OCI metadata ----
LABEL org.opencontainers.image.title="flask-microservice" \
      org.opencontainers.image.description="Flask app with PostgreSQL + Redis" \
      org.opencontainers.image.version="1.0.0" \
      maintainer="azim"

# ---- Runtime environment ----
# PYTHONUNBUFFERED: logs flush immediately to `docker logs`.
# PYTHONDONTWRITEBYTECODE: no .pyc clutter.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=5000 \
    LOG_DIR=/var/log/app

# ---- Non-root user (appuser, UID 1000) ----
RUN groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin appuser

# ---- Copy installed packages from builder ----
COPY --from=builder /install /usr/local

WORKDIR /app
COPY app.py .

# Log directory owned by the non-root user (mounted as a volume in compose).
RUN mkdir -p ${LOG_DIR} && chown -R appuser:appuser ${LOG_DIR} /app

USER appuser

# ---- Documented port & env ----
# Exposes the Flask/gunicorn port. Configurable env vars:
#   DATABASE_URL, REDIS_URL, APP_PORT, LOG_DIR
EXPOSE 5000

# ---- Health check ----
# Hits /health; container is unhealthy after 3 consecutive failures.
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD python -c "import urllib.request,sys; \
        sys.exit(0) if urllib.request.urlopen('http://localhost:5000/health', timeout=5).status==200 else sys.exit(1)" \
        || exit 1

# ---- Run with gunicorn (production WSGI server) ----
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]
