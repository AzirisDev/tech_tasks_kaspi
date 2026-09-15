"""Unit tests — no live Postgres/Redis; dependencies are monkeypatched."""
import pytest

import app as appmod


@pytest.fixture
def client():
    appmod.app.config.update(TESTING=True)
    return appmod.app.test_client()


# ---------- /version : no external deps ----------
def test_version_ok(client):
    resp = client.get("/version")
    assert resp.status_code == 200
    data = resp.get_json()
    assert "version" in data
    assert "env" in data


# ---------- /health : both deps healthy ----------
def test_health_all_ok(client, monkeypatch):
    monkeypatch.setattr(appmod, "check_postgres", lambda: True)
    monkeypatch.setattr(appmod, "check_redis", lambda: True)
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["status"] == "ok"
    assert data["checks"]["postgres"] == "ok"
    assert data["checks"]["redis"] == "ok"


# ---------- /health : postgres down -> 503 ----------
def test_health_postgres_down(client, monkeypatch):

    def boom():
        raise RuntimeError("db unreachable")
    monkeypatch.setattr(appmod, "check_postgres", boom)
    monkeypatch.setattr(appmod, "check_redis", lambda: True)
    resp = client.get("/health")
    assert resp.status_code == 503
    assert resp.get_json()["status"] == "degraded"


# ---------- /health : redis down -> 503 ----------
def test_health_redis_down(client, monkeypatch):

    def boom():
        raise RuntimeError("redis unreachable")
    monkeypatch.setattr(appmod, "check_postgres", lambda: True)
    monkeypatch.setattr(appmod, "check_redis", boom)
    resp = client.get("/health")
    assert resp.status_code == 503


# ---------- / : redis + db mocked ----------
def test_index_with_mocks(client, monkeypatch):

    class FakeRedis:

        def incr(self, key):
            return 42

    class FakeCursor:

        def execute(self, *a):
            return None

        def fetchone(self):
            from datetime import datetime, timezone
            return (datetime(2026, 1, 1, tzinfo=timezone.utc),)

    class FakeConn:

        def cursor(self):
            return FakeCursor()

        def close(self):
            return None

    monkeypatch.setattr(appmod, "get_redis_client", lambda: FakeRedis())
    monkeypatch.setattr(appmod, "get_db_connection", lambda: FakeConn())
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["hits"] == 42
    assert data["db_time"].startswith("2026-01-01")


# ---------- / : redis failing is handled gracefully ----------
def test_index_redis_failure_graceful(client, monkeypatch):

    def boom():
        raise RuntimeError("no redis")
    monkeypatch.setattr(appmod, "get_redis_client", boom)
    monkeypatch.setattr(appmod, "get_db_connection", boom)
    resp = client.get("/")
    assert resp.status_code == 200          # endpoint still responds
    data = resp.get_json()
    assert data["hits"] is None
    assert data["db_time"] is None
