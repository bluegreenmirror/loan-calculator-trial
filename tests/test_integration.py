import json
import os
import subprocess
import time

import pytest
import requests


@pytest.fixture(scope="module")
def live_server(tmp_path_factory):
    data_dir = tmp_path_factory.mktemp("data")
    env = os.environ.copy()
    env["PERSIST_DIR"] = str(data_dir)
    proc = subprocess.Popen(
        ["uvicorn", "api.app:app", "--port", "8001"], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    time.sleep(1)
    yield "http://127.0.0.1:8001", data_dir
    proc.terminate()
    proc.wait()


def test_integration_quote(live_server):
    base_url, _ = live_server
    payload = {
        "vehicle_price": 20000,
        "down_payment": 2000,
        "apr": 3.0,
        "term_months": 60,
        "tax_rate": 0.07,
        "fees": 500,
        "trade_in_value": 0,
    }
    resp = requests.post(f"{base_url}/api/quote", json=payload)
    assert resp.status_code == 200
    assert resp.json() == {
        "amount_financed": 19900.0,
        "monthly_payment": 357.58,
        "total_interest": 1554.62,
        "total_cost": 21454.62,
    }


def test_integration_lead_persistence(live_server):
    base_url, data_dir = live_server
    payload = {"name": "Alice", "email": "alice@example.com", "phone": "+12345678901"}
    resp = requests.post(f"{base_url}/api/leads", json=payload)
    assert resp.status_code == 200
    with open(data_dir / "leads.json") as f:
        data = json.load(f)
    assert data[0]["email"] == "alice@example.com"


def test_integration_track_persistence(live_server):
    base_url, data_dir = live_server
    payload = {"affiliate": "partner1"}
    resp = requests.post(f"{base_url}/api/track", json=payload)
    assert resp.status_code == 200
    with open(data_dir / "tracks.json") as f:
        data = json.load(f)
    assert data[0]["affiliate"] == "partner1"
