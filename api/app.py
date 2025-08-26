import json
import os
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

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
    apr: float = Field(..., gt=0)
    term_months: int = Field(..., gt=0)
    tax_rate: float = 0.0
    fees: float = 0.0
    trade_in_value: float = 0.0


class QuoteResp(BaseModel):
    amount_financed: float
    monthly_payment: float
    total_interest: float
    total_cost: float


@app.get("/api/health")
def health():
    return {"ok": True}


@app.post("/api/quote", response_model=QuoteResp)
def quote(q: QuoteReq):
    # Corrected calculation
    amount_after_trade_in = q.vehicle_price - q.trade_in_value
    taxes = amount_after_trade_in * q.tax_rate
    principal = amount_after_trade_in + taxes + q.fees - q.down_payment
    principal = max(principal, 0)

    if q.term_months <= 0:
        return QuoteResp(
            amount_financed=round(principal, 2),
            monthly_payment=0,
            total_interest=0,
            total_cost=round(principal, 2),
        )

    r = q.apr / 100 / 12
    if r == 0:
        monthly = principal / q.term_months
    else:
        monthly = (
            principal * (r * (1 + r) ** q.term_months) / ((1 + r) ** q.term_months - 1)
        )

    total_cost = monthly * q.term_months
    total_interest = total_cost - principal

    return QuoteResp(
        amount_financed=round(principal, 2),
        monthly_payment=round(monthly, 2),
        total_interest=round(max(total_interest, 0), 2),
        total_cost=round(total_cost, 2),
    )


class LeadReq(BaseModel):
    name: str
    email: str
    phone: str | None = None
    vehicle_type: str | None = None
    price: float | None = None
    affiliate: str | None = None


class LeadResp(BaseModel):
    message: str


@app.post("/api/leads", response_model=LeadResp)
def create_lead(lead: LeadReq):
    leads_file = "leads.json"
    lead_entry = lead.dict()
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
    affiliate: str


class TrackResp(BaseModel):
    message: str


@app.post("/api/track", response_model=TrackResp)
def track_click(track: TrackReq):
    track_file = "tracks.json"
    entry = {"affiliate": track.affiliate, "timestamp": datetime.utcnow().isoformat()}
    if os.path.exists(track_file):
        with open(track_file) as f:
            data = json.load(f)
    else:
        data = []
    data.append(entry)
    with open(track_file, "w") as f:
        json.dump(data, f)
    return TrackResp(message="Tracked")
