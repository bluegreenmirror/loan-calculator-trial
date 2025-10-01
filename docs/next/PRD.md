# Vehicle Loan Marketplace PRD (Product Development)

**Product**: Vehicle Loan Calculator & Lead Marketplace\
**Codebase**: loan-calculator-trial\
**Date**: 2025-08-30\
**Status**: Draft for implementation (v1.0)

## 1. Summary

Build a focused vehicle loan marketplace that converts calculator users into qualified leads for affiliate lenders and local dealerships. Monetize via affiliate payouts and dealer subscriptions while maintaining a fast, trustworthy calculator UX.

## 2. Goals & Non-Goals

### Goals

- MVP: High-converting calculator + lead form with affiliate/UTM capture and Postgres persistence.
- V1: Add amortization schedule, email notifications, and self-serve dealer portal (read-only lead export).
- Reliability: Blue/green deploys with automated smoke tests and error budgets.
- Compliance: Clear disclaimers, consent, data retention policy.

### Non-Goals

- Hard credit pulls or direct lending.
- Complex underwriting or rate comparison engine in MVP.
- Native mobile apps (mobile web only initially).

## 3. Personas

- **Consumer**: Shopping for financing for Auto, RV, Motorcycle, or Jet Ski. Wants quick payment estimate and next steps without impacting credit.
- **Dealer**: Wants more finance-ready leads with price context and contact details, simple export/reporting.
- **Affiliate Partner**: Sends traffic and expects accurate tracking and timely reporting.

## 4. User Stories (MVP)

- As a Consumer, I can input vehicle price, term, APR, tax, fees and see monthly payment and total cost instantly.
- As a Consumer, I can submit my contact info to get matched with a lender or dealer.
- As a Marketer, I can tag traffic with UTM parameters and see which campaigns generate leads.
- As a Developer, I can call `/api/quote` to compute payments and `/api/leads` to post leads.
- As Ops, I can deploy a new revision with blue/green and validate before switching.
- As Compliance, I see a clear disclosure that the site is a demo or marketing site and does not guarantee offers.

## 5. Scope

### In

- Calculator UI (four presets), animated result, pie chart, amortization table.
- Lead capture modal with validation (email required, phone optional with 10-15 digits, optional leading `+`).
- Affiliate tracking: accept `aff` and `utm_*` in query string; store server-side on submit and clicks.
- Postgres migration for leads and tracking; JSON file fallback for local dev.
- Admin-less exports (CSV) via secure signed link (time-limited) or CLI.
- Email notification (to internal ops mailbox) when a new lead is created (V1).

### Out (MVP)

- Real-time lender pricing.
- Dealer self-serve onboarding and billing.
- Multi-language UI (defer).

## 6. Functional Requirements

- **Calculator**: Inputs: price, down payment, trade-in value, fees, APR, term months, tax rate. Output: payment, total interest, total cost, amount financed; optional amortization table (V1).
- **Lead Form**: first_name, last_name, email (required), phone (optional), vehicle_type, vehicle_price, affiliate, utm_source/medium/campaign, ip, user_agent.
- **API**: `GET /api/health`, `POST /api/quote`, `POST /api/leads`, `POST /api/track` (for click/visit). See API_SPEC.md.
- **Persistence**: Postgres tables `leads`, `quotes`, `tracks`. JSON fallback for dev.
- **Security**: TLS in prod, input validation, basic rate limiting, IP logging, secret management via `.env`/CI.
- **Observability**: request logs, structured error logs; minimal metrics counters (leads_created_total, quote_requests_total).
- **Deploy**: Blue/green only, with `make validate-prod` smoke tests.

## 7. Non-Functional Requirements

- **Performance**: First contentful paint \< 1.0s on broadband; `/api/quote` p95 \< 50ms under 100 RPS.
- **Availability**: 99.9% monthly for public endpoints.
- **Data Retention**: Leads: 18 months; Raw tracking: 6 months; Configurable via env.
- **Privacy**: Consent checkbox with link to Privacy Policy. Opt-out for marketing.
- **Accessibility**: WCAG 2.1 AA for form labels, focus states, contrast.
- **Compatibility**: Latest Chrome/Safari/Edge + recent mobile.

## 8. Success Metrics (MVP Targets)

- Calculator-to-lead conversion: >= 6% on mobile traffic.
- Cost per qualified lead (paid): within affiliate payout margin.
- Page bounce rate: \< 45% on organic.
- Lead acceptance rate by partner: >= 70% of submitted leads.

## 9. Milestones

- **M0 (week 0-1)**: Postgres migration + minimal ORM.
- **M1 (week 2)**: Lead form wired to DB, server-side UTM capture, CSV export.
- **M2 (week 3)**: Amortization table, email notifications, smoke tests in CI.
- **M3 (week 4)**: First affiliate integration live + campaign launch.
- **M4 (week 5-6)**: Dealer pilot (embed), feedback cycle.

## 10. Risks & Mitigations

- **Low conversion**: Add inline trust, form fewer fields, reassure “no hard pull”.
- **Affiliate rejection**: Validate email/phone formats; throttle low-quality sources.
- **Ops incidents**: Blue/green with automatic rollback and health gates.

## 11. Open Questions

- Which affiliate networks approve powersports leads fastest?
- Do we need TCPA-specific consent language for SMS outreach by partners?
