# =====================================================================
#  Multi-stage Dockerfile for the Flask microservice — Alpine variant
#  Final image target: < 200 MB (typically ~90-110 MB on alpine)
# =====================================================================

# ---------- Stage 1: builder ----------------------------------------
# Alpine has no manylinux wheels for psycopg2, so we compile it here
# with the full toolchain, then copy only the built result forward.
FROM python:3.12-alpine AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build-time deps for compiling psycopg2 (postgresql-dev + gcc/musl).
# hadolint ignore=DL3018
RUN apk add --no-cache \
        build-base \
        postgresql-dev \
        python3-dev \
        libffi-dev

WORKDIR /build
COPY requirements.txt .

# Build wheels into /install prefix. --no-compile skips .pyc to save space.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: production -------------------------------------
FROM python:3.12-alpine AS production

LABEL org.opencontainers.image.title="flask-microservice" \
      org.opencontainers.image.description="Flask app with PostgreSQL + Redis" \
      org.opencontainers.image.version="1.0.0" \
      maintainer="azim"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=5000 \
    LOG_DIR=/var/log/app

# Runtime shared lib for psycopg2 (libpq) — NOT the full postgresql-dev.
# This is the only OS package the final image needs.
# hadolint ignore=DL3018
RUN apk add --no-cache libpq \
    && addgroup -g 1000 appuser \
    && adduser -u 1000 -G appuser -h /home/appuser -s /sbin/nologin -D appuser

# Copy the compiled Python packages from the builder.
COPY --from=builder /install /usr/local

WORKDIR /app
COPY app.py .

RUN mkdir -p ${LOG_DIR} && chown -R appuser:appuser ${LOG_DIR} /app

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://localhost:5000/health', timeout=5).status==200 else sys.exit(1)" \
        || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]
