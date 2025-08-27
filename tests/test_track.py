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
