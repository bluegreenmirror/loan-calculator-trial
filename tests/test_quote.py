import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from api.app import QuoteReq, app, quote

client = TestClient(app)


def test_quote_basic():
    req = QuoteReq(
        vehicle_price=20000,
        down_payment=2000,
        apr=3.0,
        term_months=60,
        tax_rate=0.07,
        fees=500,
        trade_in_value=0,
    )
    resp = quote(req)
    assert resp.amount_financed == 19900.0
    assert resp.monthly_payment == 357.58
    assert resp.total_interest == 1554.61
    assert resp.total_cost == 21454.61

    assert len(resp.schedule) == req.term_months
    first = resp.schedule[0]
    assert first.month == 1
    assert first.payment == resp.monthly_payment
    assert first.principal == pytest.approx(307.83)
    assert first.interest == pytest.approx(49.75)
    assert first.balance == pytest.approx(19592.17)

    last = resp.schedule[-1]
    assert last.month == req.term_months
    assert last.balance == pytest.approx(0.0, abs=0.01)

    total_principal = round(sum(row.principal for row in resp.schedule), 2)
    total_interest = round(sum(row.interest for row in resp.schedule), 2)
    assert total_principal == resp.amount_financed
    assert total_interest == resp.total_interest
    assert round(total_principal + total_interest, 2) == resp.total_cost


def test_quote_zero_apr():
    req = QuoteReq(
        vehicle_price=10000,
        down_payment=0,
        apr=0.0,
        term_months=10,
        tax_rate=0.0,
        fees=0.0,
        trade_in_value=0.0,
    )
    resp = quote(req)
    assert resp.amount_financed == 10000.0
    assert resp.monthly_payment == 1000.0
    assert resp.total_interest == 0.0
    assert resp.total_cost == 10000.0

    assert len(resp.schedule) == req.term_months
    assert all(row.interest == 0.0 for row in resp.schedule)
    assert resp.schedule[-1].balance == pytest.approx(0.0, abs=0.01)


def test_quote_zero_term_validation():
    with pytest.raises(ValidationError):
        QuoteReq(
            vehicle_price=10000,
            down_payment=1000,
            apr=5.0,
            term_months=0,
            tax_rate=0.0,
            fees=0.0,
            trade_in_value=0.0,
        )


def test_quote_trade_in_exceeds_price():
    req = QuoteReq(
        vehicle_price=10000,
        down_payment=0,
        apr=5.0,
        term_months=60,
        tax_rate=0.0,
        fees=0.0,
        trade_in_value=15000,
    )
    resp = quote(req)
    assert resp.amount_financed == 0
    assert resp.monthly_payment == 0
    assert resp.total_interest == 0
    assert resp.total_cost == 0
    assert len(resp.schedule) == req.term_months
    assert all(row.payment == 0 for row in resp.schedule)


def test_quote_negative_apr_validation():
    with pytest.raises(ValidationError):
        QuoteReq(
            vehicle_price=10000,
            down_payment=0,
            apr=-1.0,
            term_months=60,
            tax_rate=0.0,
            fees=0.0,
            trade_in_value=0.0,
        )


def test_health_endpoint():
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}


def test_quote_endpoint_basic():
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
    data = resp.json()
    assert data["amount_financed"] == 19900.0
    assert data["monthly_payment"] == 357.58
    assert data["total_interest"] == 1554.61
    assert data["total_cost"] == 21454.61
    assert isinstance(data["schedule"], list)
    assert len(data["schedule"]) == payload["term_months"]
    first = data["schedule"][0]
    assert first["month"] == 1
    assert first["payment"] == data["monthly_payment"]
    assert first["principal"] == pytest.approx(307.83)
    assert first["interest"] == pytest.approx(49.75)
    last = data["schedule"][-1]
    assert last["month"] == payload["term_months"]
    assert last["balance"] == pytest.approx(0.0, abs=0.01)
    principal_sum = round(sum(row["principal"] for row in data["schedule"]), 2)
    interest_sum = round(sum(row["interest"] for row in data["schedule"]), 2)
    assert principal_sum == data["amount_financed"]
    assert interest_sum == data["total_interest"]


def test_quote_endpoint_validation_error():
    payload = {
        "vehicle_price": 10000,
        "down_payment": 0,
        "apr": -1.0,
        "term_months": 60,
        "tax_rate": 0.0,
        "fees": 0.0,
        "trade_in_value": 0.0,
    }
    resp = client.post("/api/quote", json=payload)
    assert resp.status_code == 422
