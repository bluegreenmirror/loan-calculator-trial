# Technical Design for Loan Calculator Platform v2

## Architecture

- **Frontend**: Modular web components for each calculator and the partners page.
- **Backend**: REST API built with FastAPI under `/api/v1/` providing calculation
  logic and partner offer management.
- **Database**: PostgreSQL instance on Google Cloud SQL accessed via SQLAlchemy
  with migration scripts in `scripts/migrations`.
- **Hosting**: Containers deployed to Cloud Run; static assets served via Caddy.

## Module Layout

```
docs/
api/
  calculators/
    vehicle.py
    mortgage.py
    heloc.py
    personal.py
  partners/
    endpoints.py
web/
  components/
    calculator-widget.js
    partner-cards.js
```

## APIs

- `POST /api/v1/calculators/<type>`: returns monthly amortization schedule.
- `GET /api/v1/partners`: returns swipe card data.
- `POST /api/v1/leads`: captures user email and returns a token required for
  amortization schedules or export downloads.

## Lead Capture and Verification

- Emails are stored in a `leads` table with fields for address, token, and
  verification status.
- Calculator endpoints verify a valid lead token before generating amortization
  schedules or exports.
- Future enhancement: send verification emails containing a signed link that
  marks the lead as verified when clicked.

## Cloud SQL Migration

- Use `scripts/migrate.py` to apply Alembic migrations.
- Environment variables stored in `.env` and `.env.example` documents.
