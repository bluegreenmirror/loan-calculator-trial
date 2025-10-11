# Loan Calculator Platform v2 — Consolidated PRD

## Overview

Deliver a fast, responsive, and extensible loan calculator platform that supports
multiple loan types (vehicle, mortgage, HELOC, personal) with embeddable widgets,
affiliate/partners integrations, and lead capture. v2 standardizes versioned APIs, adds
amortization schedules, and lays groundwork for Cloud SQL-backed persistence and
analytics.

## Goals

- Platform: Modular calculators with shared math/utilities and versioned REST APIs under
  `/api/v1`.
- Calculators: Vehicle, mortgage, HELOC, and personal loan calculators with presets and
  mobile-first UI.
- Amortization: API returns monthly schedules (principal/interest breakdown) and totals.
- Lead Gen: Capture email/phone; issue tokens required to view/download
  amortization/export artifacts.
- Affiliates/Partners: Track UTMs/affiliate IDs; add swipe-based partners/products UI
  and API.
- Deployment: Containerized, Caddy fronted, blue/green deployments; Cloudflare Full
  (strict) in prod.

## Non-Goals (v2)

- Full CRM or complex lead nurturing/automation.
- Multi-language UI and advanced A/B testing.
- Real lender decisioning or credit pulls.

## Personas

- Borrower: explores payment options and schedules; may submit contact info.
- Affiliate Marketer: embeds calculators, routes traffic to offers.
- Dealer/Lender: integrates API; reviews leads and engagement metrics.
- Mobile Developer: consumes versioned APIs to embed calculators in native apps.

## Functional Requirements

1. Calculators/UI

- Inputs: amount/price, down payment, trade-in (vehicle), fees, tax rate, APR, term.
- Presets per loan type; responsive UI; embeddable widget variant.
- Outputs: monthly payment, amount financed, total cost, total interest; pie/legend
  chart.

1. APIs (v1)

- `GET /api/v1/health`: service health.
- `POST /api/v1/calculators/<type>`: compute payments and amortization schedule.
- `POST /api/v1/leads`: capture lead; respond with token used to access gated features.
- `POST /api/v1/track`: record affiliate/UTM events.
- `GET /api/v1/partners`: list partner offers/cards (MVP static or JSON-backed).

1. Lead Token Gating

- Viewing amortization schedules and exports requires a valid token from `/leads`.
- Store token + basic lead data; optionally verify later (future scope).

1. Affiliate/UTM Tracking

- Accept affiliate and UTM parameters; persist with timestamps.
- Surface minimal analytics (counts, CTRs) in future iterations.

1. Persistence

- v2 baseline: migrate from JSON files to Postgres; Alembic migrations; Cloud SQL
  targeted for prod.

## Non-Functional Requirements

- Performance: API p95 \< 300ms typical calc; initial page \< 1s on broadband.
- Reliability: health endpoint; smoke tests for critical paths.
- Security/Privacy: HTTPS in prod; input validation; no secrets in repo; basic PII
  handling guidance.
- Maintainability: modular code; tests; linted and formatted; versioned endpoints.

## Success Metrics (MVP Targets)

- 99.9% uptime for `/api/v1/health` and calculators API in prod.
- 95% of amortization requests succeed under p95 \< 300ms.
- Lead conversion rate tracked from views → token issuance.
- Zero secrets in repo; CI passes lint/test/smoke for every PR.

## Milestones

1. API v1 Scaffold

- Routers under `/api/v1`; legacy `/api/*` remains temporarily.
- Tests + curl examples; CI updated.

1. Vehicle Calculator + Amortization

- Implement schedule math; unit tests validate totals and per-period sums.

1. Postgres Baseline

- Compose Postgres for dev; SQLAlchemy models (leads, tracks, partners); Alembic init +
  first migration; `.env.example` DATABASE_URL placeholder.

1. Lead Token Gate

- `/leads` issues token; calculators schedule/export path requires token; integration
  tests.

1. Additional Calculators

- Mortgage, HELOC, personal calculators share common math utilities; tests for each.

1. Partners API + UI

- `GET /partners` returns card data; minimal swipe UI on web; e2e smoke.

1. Staging/Prod Readiness

- CI runs migrations; smoke tests for `/api/v1/*`; Caddy validate/adapt passes.
- Blue/green deploy docs and validate_prod scripts updated.

## Risks & Mitigations

- Scope creep across loan types → Mitigate by modularizing math and shipping per-type.
- DB migration complexity → Start with minimal schema; add migrations incrementally.
- Token abuse/privacy → Store minimal PII; rotate tokens; document retention.

## Open Questions

- Do partners require an admin interface in v2, or JSON-config only?
- Should amortization exports support CSV-only in v2, with PDF later?
- Will staging mirror Cloud SQL or use a managed sandbox DB?
