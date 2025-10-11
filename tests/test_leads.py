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


def test_lead_multiple_appends(tmp_path, monkeypatch):
    """Two valid leads should append and preserve order."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload1 = {"name": "A1", "email": "a1@example.com", "phone": "+12345678901"}
    payload2 = {"name": "A2", "email": "a2@example.com", "phone": "+12345678902"}
    resp1 = client.post("/api/leads", json=payload1)
    resp2 = client.post("/api/leads", json=payload2)
    assert resp1.status_code == 200 and resp2.status_code == 200
    leads_file = tmp_path / "leads.json"
    data = json.loads(leads_file.read_text())
    assert len(data) == 2
    assert data[0]["email"] == "a1@example.com"
    assert data[1]["email"] == "a2@example.com"


def test_lead_persists_affiliate_and_utms(tmp_path, monkeypatch):
    """Affiliate and UTM metadata should be persisted when supplied."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    payload = {
        "name": "Attribution Test",
        "email": "attr@example.com",
        "phone": "+12345678901",
        "affiliate": "aff123",
        "utm_source": "newsletter",
        "utm_medium": "email",
        "utm_campaign": "spring-launch",
        "utm_term": "auto-loans",
        "utm_content": "cta-button",
    }
    resp = client.post("/api/leads", json=payload)
    assert resp.status_code == 200
    data = json.loads((tmp_path / "leads.json").read_text())
    lead = data[0]
    assert lead["affiliate"] == "aff123"
    assert lead["utm_source"] == "newsletter"
    assert lead["utm_medium"] == "email"
    assert lead["utm_campaign"] == "spring-launch"
    assert lead["utm_term"] == "auto-loans"
    assert lead["utm_content"] == "cta-button"


def test_lead_corrupt_file_returns_500_and_unmodified(tmp_path, monkeypatch):
    """If leads.json is corrupt, API should return 500 and not overwrite it."""
    monkeypatch.setenv("PERSIST_DIR", str(tmp_path))
    leads_file = tmp_path / "leads.json"
    original = "not valid json"
    leads_file.write_text(original)
    payload = {"name": "Bad", "email": "bad@example.com", "phone": "+12345678901"}
    # Use a client that does not raise server exceptions so we can assert 500
    from fastapi.testclient import TestClient as _TC

    with _TC(app, raise_server_exceptions=False) as c:
        resp = c.post("/api/leads", json=payload)
    assert resp.status_code == 500
    assert leads_file.read_text() == original
