"""Integration test — exercises Redis via fakeredis (in-memory, real client
API) to prove the caching path end-to-end without a running server."""
import fakeredis
import app as appmod


def test_index_integration_with_fakeredis(monkeypatch):
    fake = fakeredis.FakeStrictRedis()
    monkeypatch.setattr(appmod, "get_redis_client", lambda: fake)

    # DB stub returns a fixed time
    class FakeCursor:

        def execute(self, *a): return None

        def fetchone(self):
            from datetime import datetime, timezone
            return (datetime(2026, 6, 1, tzinfo=timezone.utc),)

    class FakeConn:

        def cursor(self): return FakeCursor()

        def close(self): return None
    monkeypatch.setattr(appmod, "get_db_connection", lambda: FakeConn())

    client = appmod.app.test_client()
    r1 = client.get("/").get_json()
    r2 = client.get("/").get_json()
    # fakeredis really increments -> integration of the counter path
    assert r2["hits"] == r1["hits"] + 1
