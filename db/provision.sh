#!/usr/bin/env bash
# Provision PostgreSQL 14 on Ubuntu 22.04 and load the devops_test database.
# Usage: sudo ./provision.sh
set -euo pipefail

DB_NAME="devops_test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/4] Installing PostgreSQL 14..."
apt-get update -qq
apt-get install -y postgresql-14 postgresql-contrib-14

echo "[2/4] Ensuring service is running..."
systemctl enable --now postgresql

echo "[3/4] Creating database '${DB_NAME}'..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" \
  | grep -q 1 || sudo -u postgres createdb "${DB_NAME}"

echo "[4/4] Loading schema and seed data..."
sudo -u postgres psql -d "${DB_NAME}" < "${SCRIPT_DIR}/schema.sql"
sudo -u postgres psql -d "${DB_NAME}" < "${SCRIPT_DIR}/seed.sql"

echo "Done. Run queries with:"
echo "  sudo -u postgres psql -d ${DB_NAME} < ${SCRIPT_DIR}/queries.sql"
