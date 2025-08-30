import json

from fastapi.testclient import TestClient

from api.app import app

client = TestClient(app)


def test_track_persistence(tmp_path, monkeypatch):
    """Tests that a valid tracking event is persisted to a JSON file."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"affiliate": "partner1"}
    resp = client.post("/api/track", json=payload)
    assert resp.status_code == 200
    track_file = tmp_path / "tracks.json"
    assert track_file.exists()
    data = json.loads(track_file.read_text())
    assert data[0]["affiliate"] == "partner1"


def test_track_invalid_affiliate(tmp_path, monkeypatch):
    """Tests that a tracking event with an empty affiliate is rejected."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"affiliate": ""}
    resp = client.post("/api/track", json=payload)
    assert resp.status_code == 422
    assert not (tmp_path / "tracks.json").exists()


def test_track_multiple_appends(tmp_path, monkeypatch):
    """Two valid track events should append and preserve order."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload1 = {"affiliate": "p1"}
    payload2 = {"affiliate": "p2"}
    r1 = client.post("/api/track", json=payload1)
    r2 = client.post("/api/track", json=payload2)
    assert r1.status_code == 200 and r2.status_code == 200
    track_file = tmp_path / "tracks.json"
    data = json.loads(track_file.read_text())
    assert len(data) == 2
    assert data[0]["affiliate"] == "p1"
    assert data[1]["affiliate"] == "p2"


def test_track_corrupt_file_returns_500_and_unmodified(tmp_path, monkeypatch):
    """If tracks.json is corrupt, API should return 500 and not overwrite it."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    track_file = tmp_path / "tracks.json"
    original = "not valid json"
    track_file.write_text(original)
    payload = {"affiliate": "p1"}
    # Use a client that does not raise server exceptions so we can assert 500
    from fastapi.testclient import TestClient as _TC

    with _TC(app, raise_server_exceptions=False) as c:
        resp = c.post("/api/track", json=payload)
    assert resp.status_code == 500
    assert track_file.read_text() == original


def test_track_persists_utms_when_provided(tmp_path, monkeypatch):
    """Posting UTMs along with affiliate should persist those fields server-side."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {
        "affiliate": "partnerX",
        "utm_source": "newsletter",
        "utm_medium": "email",
        "utm_campaign": "summer-2025",
        "utm_term": "low-apr",
        "utm_content": "cta-button"
    }
    resp = client.post("/api/track", json=payload)
    assert resp.status_code == 200
    data = json.loads((tmp_path / "tracks.json").read_text())
    assert data[0]["affiliate"] == "partnerX"
    # UTMs are optional but should be present when provided
    assert data[0]["utm_source"] == "newsletter"
    assert data[0]["utm_medium"] == "email"
    assert data[0]["utm_campaign"] == "summer-2025"
    assert data[0]["utm_term"] == "low-apr"
    assert data[0]["utm_content"] == "cta-button"
