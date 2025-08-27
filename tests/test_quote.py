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
    assert resp.total_interest == 1554.62
    assert resp.total_cost == 21454.62


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
    assert resp.json() == {
        "amount_financed": 19900.0,
        "monthly_payment": 357.58,
        "total_interest": 1554.62,
        "total_cost": 21454.62,
    }


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
