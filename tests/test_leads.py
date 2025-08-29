import json

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from api.app import LeadReq, app

client = TestClient(app)


def test_lead_persistence(tmp_path, monkeypatch):
    """Tests that a valid lead is persisted to a JSON file."""
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
    """Tests that a lead with an invalid email address is rejected."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "Bob", "email": "invalid", "phone": "+12345678901"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422


def test_lead_invalid_phone(tmp_path, monkeypatch):
    """Tests that a lead with an invalid phone number is rejected."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "Bob", "email": "bob@example.com", "phone": "bad"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422


def test_lead_invalid_name(tmp_path, monkeypatch):
    """Tests that a lead with an empty name is rejected."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "", "email": "bob@example.com", "phone": "+12345678901"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422


def test_lead_invalid_not_persisted(tmp_path, monkeypatch):
    """Invalid lead submissions should not create a persistence file."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {"name": "", "email": "bob@example.com"}
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 422
    assert not (tmp_path / "leads.json").exists()


def test_lead_model_phone_validation():
    """Tests the phone number validation logic in the LeadReq model."""
    LeadReq(name="Carl", email="carl@example.com", phone="+12345678901")
    with pytest.raises(ValidationError):
        LeadReq(name="Carl", email="carl@example.com", phone="123")
