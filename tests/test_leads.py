import json

from fastapi.testclient import TestClient

from api.app import app

client = TestClient(app)


def test_lead_persistence(tmp_path, monkeypatch):
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {
        "name": "Alice",
        "email": "alice@example.com",
        "phone": "+12345678901",
    }
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 200
    leads_file = tmp_path / "leads.json"
    assert leads_file.exists()
    data = json.loads(leads_file.read_text())
    assert data[0]["email"] == "alice@example.com"
    assert data[0]["phone"] == "+12345678901"


def test_lead_invalid_email(tmp_path, monkeypatch):
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "Bob", "email": "invalid", "phone": "+12345678901"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422


def test_lead_invalid_phone(tmp_path, monkeypatch):
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "Bob", "email": "bob@example.com", "phone": "bad"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422
