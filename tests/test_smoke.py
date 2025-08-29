import json

import pytest
from fastapi.testclient import TestClient

from api.app import app


@pytest.fixture()
def client(tmp_path, monkeypatch):
    """Create a TestClient that writes data under a temp directory."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    return TestClient(app)


def test_health(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}


def test_quote(client):
    payload = {
        "vehicle_price": 20000,
        "down_payment": 2000,
        "apr": 3.0,
        "term_months": 60,
    }
    resp = client.post("/api/quote", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    for key in {"amount_financed", "monthly_payment", "total_interest", "total_cost"}:
        assert key in body


def test_leads_persist(client, tmp_path):
    payload = {"name": "Alice", "email": "alice@example.com"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 200

    leads_file = tmp_path / "leads.json"
    assert leads_file.exists()
    data = json.loads(leads_file.read_text())
    assert data[0]["email"] == "alice@example.com"


def test_track_persist(client, tmp_path):
    resp = client.post("/api/track", json={"affiliate": "partner"})
    assert resp.status_code == 200

    track_file = tmp_path / "tracks.json"
    assert track_file.exists()
