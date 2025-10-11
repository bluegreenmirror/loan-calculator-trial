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
  "ok": true,
  "data": {
    "monthly_payment": 691.23,
    "amount_financed": 32000.00,
    "total_interest": 9153.80,
    "total_cost": 44153.80
  }
}
```

Validation:

- `vehicle_price > 0`, `term_months in [6..120]`, `apr in [0..100)`, rates as decimals (e.g., 9.5% => 9.5).
- Optional fields default to 0 if omitted.

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
