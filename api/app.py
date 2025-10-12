import json
import os
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal, getcontext
from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field

app = FastAPI(title="Dealer Quote API", version="0.1.0")

# Configure CORS to only allow specific origins instead of allowing all requests.
# Origins can be supplied via the ALLOWED_ORIGINS environment variable as a
# comma-separated list (e.g. "https://example.com,http://localhost:8080").
allowed_origins = [
    o.strip() for o in os.getenv("ALLOWED_ORIGINS", "").split(",") if o.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class QuoteReq(BaseModel):
    vehicle_price: float = Field(..., gt=0)
    down_payment: float = 0
    apr: float = Field(..., ge=0)
    term_months: int = Field(..., gt=0)
    tax_rate: float = 0.0
    fees: float = 0.0
    trade_in_value: float = 0.0


getcontext().prec = 28

TWO_PLACES = Decimal("0.01")


def _to_decimal(value: float) -> Decimal:
    return Decimal(str(value))


def _to_cents(value: Decimal) -> Decimal:
    return value.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


class AmortizationRow(BaseModel):
    month: int
    payment: float
    principal: float
    interest: float
    balance: float


class QuoteResp(BaseModel):
    amount_financed: float
    monthly_payment: float
    total_interest: float
    total_cost: float
    schedule: list[AmortizationRow]


@app.get("/api/health")
def health():
    return {"ok": True}


@app.post("/api/quote", response_model=QuoteResp)
def quote(q: QuoteReq):
    amount_after_trade_in = _to_decimal(q.vehicle_price) - _to_decimal(q.trade_in_value)
    taxes = amount_after_trade_in * _to_decimal(q.tax_rate)
    principal = (
        amount_after_trade_in
        + taxes
        + _to_decimal(q.fees)
        - _to_decimal(q.down_payment)
    )
    if principal < 0:
        principal = Decimal("0")
    amount_financed = _to_cents(principal)
    principal = amount_financed

    if q.term_months <= 0:
        return QuoteResp(
            amount_financed=float(amount_financed),
            monthly_payment=0,
            total_interest=0,
            total_cost=float(amount_financed),
            schedule=[],
        )

    r = _to_decimal(q.apr) / Decimal("100") / Decimal("12")
    if r == 0:
        monthly_payment_decimal = principal / q.term_months
    else:
        factor = (Decimal("1") + r) ** q.term_months
        monthly_payment_decimal = principal * (r * factor) / (factor - Decimal("1"))
    monthly_payment = _to_cents(monthly_payment_decimal)

    balance = amount_financed
    schedule: list[AmortizationRow] = []
    sum_interest = Decimal("0")
    sum_principal = Decimal("0")

    for month in range(1, q.term_months + 1):
        prev_balance = balance
        if balance == Decimal("0"):
            interest_payment = Decimal("0")
        elif r == 0:
            interest_payment = Decimal("0")
        else:
            interest_payment = _to_cents(balance * r)
        interest_payment = _to_cents(interest_payment)

        principal_payment = monthly_payment - interest_payment
        if principal_payment < Decimal("0"):
            principal_payment = Decimal("0")
            payment_amount = interest_payment
        else:
            payment_amount = monthly_payment

        is_last_period = month == q.term_months
        if principal_payment > prev_balance or is_last_period:
            principal_payment = prev_balance
            payment_amount = principal_payment + interest_payment

        principal_payment = _to_cents(principal_payment)
        payment_amount = _to_cents(payment_amount)
        balance = _to_cents(prev_balance - principal_payment)
        sum_interest += interest_payment
        sum_principal += principal_payment

        schedule.append(
            AmortizationRow(
                month=month,
                payment=float(payment_amount),
                principal=float(principal_payment),
                interest=float(interest_payment),
                balance=float(balance),
            )
        )

    sum_interest = _to_cents(sum_interest)
    sum_principal = _to_cents(sum_principal)
    total_interest = float(sum_interest)
    total_cost = float(_to_cents(sum_principal + sum_interest))

    return QuoteResp(
        amount_financed=float(amount_financed),
        monthly_payment=float(monthly_payment),
        total_interest=total_interest,
        total_cost=total_cost,
        schedule=schedule,
    )


def _data_file(filename: str) -> str:
    data_dir = os.getenv("PERSIST_DIR", "/data")
    os.makedirs(data_dir, exist_ok=True)
    return os.path.join(data_dir, filename)


class LeadReq(BaseModel):
    name: str = Field(min_length=1)
    email: EmailStr
    phone: Optional[str] = Field(default=None, pattern=r"^\+?[0-9]{10,15}$")
    vehicle_type: Optional[str] = None
    price: Optional[float] = None
    affiliate: Optional[str] = None


class LeadResp(BaseModel):
    message: str


@app.post("/api/leads", response_model=LeadResp)
def create_lead(lead: LeadReq):
    leads_file = _data_file("leads.json")
    lead_entry = lead.model_dump()
    lead_entry["timestamp"] = datetime.utcnow().isoformat()
    if os.path.exists(leads_file):
        with open(leads_file) as f:
            data = json.load(f)
    else:
        data = []
    data.append(lead_entry)
    with open(leads_file, "w") as f:
        json.dump(data, f)
    return LeadResp(message="Lead received")


class TrackReq(BaseModel):
    affiliate: str = Field(min_length=1)
    utm_source: Optional[str] = None
    utm_medium: Optional[str] = None
    utm_campaign: Optional[str] = None
    utm_term: Optional[str] = None
    utm_content: Optional[str] = None


class TrackResp(BaseModel):
    message: str


@app.post("/api/track", response_model=TrackResp)
def track_click(track: TrackReq):
    track_file = _data_file("tracks.json")
    entry = track.model_dump(exclude_none=True)
    entry["timestamp"] = datetime.utcnow().isoformat()
    if os.path.exists(track_file):
        with open(track_file) as f:
            data = json.load(f)
    else:
        data = []
    data.append(entry)
    with open(track_file, "w") as f:
        json.dump(data, f)
    return TrackResp(message="Tracked")
