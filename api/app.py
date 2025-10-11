import json
import os
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
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


def _data_file(filename: str) -> str:
    data_dir = os.getenv("PERSIST_DIR", "/data")
    os.makedirs(data_dir, exist_ok=True)
    return os.path.join(data_dir, filename)


def _static_root() -> Path | None:
    root = os.getenv("STATIC_ROOT")
    if not root:
        return None
    path = Path(root)
    if path.is_dir():
        return path
    return None


def _index_path(root: Path) -> Path | None:
    index = root / "index.html"
    if index.is_file():
        return index
    return None


def _serve_index() -> HTMLResponse:
    root = _static_root()
    if not root:
        raise HTTPException(status_code=404)
    index = _index_path(root)
    if not index:
        raise HTTPException(status_code=404)
    return HTMLResponse(index.read_text(encoding="utf-8"))


class LeadReq(BaseModel):
    name: str = Field(min_length=1)
    email: EmailStr
    phone: str | None = Field(default=None, pattern=r"^\+?[0-9]{10,15}$")
    vehicle_type: str | None = None
    price: float | None = None
    affiliate: str | None = None


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
    utm_source: str | None = None
    utm_medium: str | None = None
    utm_campaign: str | None = None
    utm_term: str | None = None
    utm_content: str | None = None


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


@app.get("/", response_class=HTMLResponse)
def serve_index():
    """Serve the SPA entrypoint when STATIC_ROOT is configured."""
    return _serve_index()


@app.get("/{path:path}")
def serve_static(path: str):
    """Serve built assets or fall back to the SPA entrypoint."""
    if path.startswith("api/"):
        raise HTTPException(status_code=404)

    root = _static_root()
    if not root:
        raise HTTPException(status_code=404)

    candidate = (root / path).resolve()
    try:
        candidate.relative_to(root)
    except ValueError as exc:  # Path traversal attempt
        raise HTTPException(status_code=404) from exc

    if candidate.is_file():
        return FileResponse(candidate)

    index = _index_path(root)
    if not index:
        raise HTTPException(status_code=404)

    return HTMLResponse(index.read_text(encoding="utf-8"))
