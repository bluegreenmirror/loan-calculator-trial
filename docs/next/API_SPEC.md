# API_SPEC.md

All responses are JSON with `application/json; charset=utf-8`. Error schema:

```json
{ "ok": false, "error": { "code": "string", "message": "string" } }
```

## GET /api/health

- 200: `{ "ok": true }`

## POST /api/quote

Compute loan terms.
Request body:

```json
{
  "vehicle_price": 35000.0,
  "down_payment": 3000.0,
  "apr": 6.9,
  "term_months": 60,
  "tax_rate": 0.095,
  "fees": 495.0,
  "trade_in_value": 0.0
}
```

Response:

```json
{
  "amount_financed": 35820.0,
  "monthly_payment": 707.59,
  "total_interest": 6635.43,
  "total_cost": 42455.43,
  "schedule": [
    {
      "month": 1,
      "payment": 707.59,
      "principal": 501.62,
      "interest": 205.97,
      "balance": 35318.38
    },
    {
      "month": 2,
      "payment": 707.59,
      "principal": 504.51,
      "interest": 203.08,
      "balance": 34813.87
    },
    {
      "month": 60,
      "payment": 707.62,
      "principal": 703.57,
      "interest": 4.05,
      "balance": 0.0
    }
  ]
}
```

- `schedule` contains one entry per month with payments rounded to cents. The final row absorbs any rounding drift so the balance closes at `$0.00`.

Validation:

- `vehicle_price > 0`, `term_months > 0`, `apr >= 0`, and amounts may be passed as whole numbers or decimals (`9.5` for 9.5%).
- `down_payment`, `fees`, `tax_rate`, and `trade_in_value` default to `0` when omitted.
- Zero-APR loans are supported; `interest` will be `0.0` for every row.

## POST /api/leads

Create a lead.
Request body (fields marked * required):

```json
{
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane@example.com",
  "phone": "+14155551212",
  "vehicle_type": "auto",
  "vehicle_price": 35000,
  "affiliate": "partnerX",
  "utm_source": "gads",
  "utm_medium": "cpc",
  "utm_campaign": "rv_loans_july"
}
```

Response:

```json
{ "ok": true, "data": { "lead_id": "ld_01J..." } }
```

Validation:

- `email` required, RFC 5322 basic pattern.
- `phone` optional, digits 10-15 with optional leading `+`.
- `vehicle_type` in `["auto","rv","motorcycle","jet_ski"]`.

## POST /api/track

Track a click or visit. Recommended to call on landing.
Request:

```json
{
  "affiliate": "partnerX",
  "utm_source": "gads",
  "utm_medium": "cpc",
  "utm_campaign": "rv_loans_july",
  "click_id": "abc123"
}
```

Response: `{ "ok": true }`

## Headers and Metadata

- `X-Forwarded-For` honored for client IP. Server also logs UA and referrer.
- Basic rate limit: 60 req/min per IP for write endpoints.

## Error Codes

- `VALIDATION_ERROR`, `RATE_LIMITED`, `NOT_FOUND`, `SERVER_ERROR`.
