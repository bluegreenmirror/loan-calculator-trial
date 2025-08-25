from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="Dealer Quote API", version="0.1.0")

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
    taxable_base = max(q.vehicle_price - q.trade_in_value, 0)
    taxes = taxable_base * q.tax_rate
    principal = max(q.vehicle_price + taxes + q.fees - q.down_payment - q.trade_in_value, 0)
    r = q.apr/100/12
    if r == 0:
        monthly = principal / q.term_months
    else:
        monthly = principal * (r * (1 + r)**q.term_months) / ((1 + r)**q.term_months - 1)
    total = monthly * q.term_months
    return QuoteResp(
        amount_financed=round(principal, 2),
        monthly_payment=round(monthly, 2),
        total_interest=round(max(total - principal, 0), 2),
        total_cost=round(total, 2)
    )
