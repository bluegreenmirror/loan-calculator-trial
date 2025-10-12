import json
import pytest
from fastapi.testclient import TestClient

from api.app import app


@pytest.fixture(scope="function")
def client_and_dir(tmp_path_factory, monkeypatch):
    data_dir = tmp_path_factory.mktemp("data")
    monkeypatch.setenv("PERSIST_DIR", str(data_dir))
    with TestClient(app) as client:
        yield client, data_dir


def test_integration_quote(client_and_dir):
    """Tests the /api/quote endpoint with a valid request."""
    client, _ = client_and_dir
    payload = {
        "vehicle_price": 20000,
        "down_payment": 2000,
        "apr": 3.0,
        "term_months": 60,
        "tax_rate": 0.07,
        "fees": 500,
        "trade_in_value": 0,
    }
    resp = client.post("/api/quote", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["amount_financed"] == 19900.0
    assert body["monthly_payment"] == 357.58
    assert body["total_interest"] == 1554.61
    assert body["total_cost"] == 21454.61
    assert isinstance(body["schedule"], list)
    assert len(body["schedule"]) == payload["term_months"]


def test_integration_lead_persistence(client_and_dir):
    """Tests that a lead submitted to /api/leads is persisted to disk."""
    client, data_dir = client_and_dir
    payload = {"name": "Alice", "email": "alice@example.com", "phone": "+12345678901"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 200
    with open(data_dir / "leads.json") as f:
        data = json.load(f)
    assert data[0]["email"] == "alice@example.com"
def test_integration_track_persistence(client_and_dir):
    """Tests that a tracking event submitted to /api/track is persisted to disk."""
    client, data_dir = client_and_dir
    payload = {"affiliate": "partner1"}
    resp = client.post("/api/track", json=payload)
    assert resp.status_code == 200
    with open(data_dir / "tracks.json") as f:
        data = json.load(f)
    assert data[0]["affiliate"] == "partner1"
