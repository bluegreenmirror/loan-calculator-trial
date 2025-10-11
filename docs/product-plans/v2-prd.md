# Loan Calculator Platform v2 — Consolidated PRD

## Overview

Build a fast, responsive, and extensible loan calculator platform that converts
traffic into qualified leads while supporting multiple loan types (vehicle,
mortgage, HELOC, personal). The experience must work as a standalone site and an
embeddable widget, standardize on versioned APIs, and lay the groundwork for
Cloud SQL-backed persistence, analytics, and affiliate monetization.

## Product Summary

- **Product**: Vehicle Loan Calculator & Lead Marketplace expanding into a
  multi-loan calculator platform.
- **Codebase**: `loan-calculator-trial`
- **Date**: 2025-08-30
- **Status**: Draft for implementation (v1.0)

## Goals

- **Platform**: Modular calculators with shared math utilities and versioned REST
  APIs under `/api/v1`.
- **Calculators**: Vehicle, mortgage, HELOC, and personal calculators with mobile-
  first UI, presets, amortization schedules, and embeddable widget variants.
- **Lead Generation**: Capture contact information, affiliate IDs, and UTMs; issue
  tokens that unlock amortization exports while logging conversion metrics.
- **Monetization**: Convert calculator users into qualified leads for affiliate
  lenders and dealerships, enabling dealer subscriptions and affiliate payouts.
- **Reliability & Deployment**: Containerized app fronted by Caddy with blue/green
  deploys, automated smoke tests, and Cloudflare Full (strict) in production.
- **Compliance & Trust**: Provide clear disclosures, data retention policies,
  accessibility, and consent management.

## Non-Goals (v2)

- Hard credit pulls, direct lending decisions, or complex underwriting logic.
- Full CRM capabilities, advanced nurture automation, or dealer billing flows.
- Native mobile apps or multi-language UI in the initial release.
- Advanced A/B testing or experimental analytics frameworks.

## Personas

- **Borrower/Consumer**: Evaluates payment options, wants instant answers without a
  credit impact, and may submit contact information.
- **Affiliate Marketer**: Embeds calculators, tags campaigns with UTMs, and expects
  timely attribution.
- **Dealer/Lender Partner**: Reviews leads, exports contact info, and integrates
  partner offers.
- **Mobile Developer**: Consumes versioned APIs to embed calculators in external
  applications.
- **Operations/Compliance**: Oversees deployments, ensures disclosures, and manages
  data retention.

## User Stories (MVP)

- As a consumer, I can input price, down payment, trade-in, fees, tax, APR, and term
  to instantly see monthly payments and total cost.
- As a consumer, I can submit my contact information to get matched with lenders or
  dealers and receive amortization exports.
- As a marketer, I can tag traffic with affiliate and UTM parameters and see which
  campaigns generate leads.
- As a developer, I can call versioned APIs to compute quotes and store leads with
  amortization schedules.
- As operations, I can deploy a new revision with blue/green tooling and validate
  health before promoting.
- As compliance, I can verify that disclosures, consent, and retention policies are
  enforced.

## Functional Requirements

### Calculators and UI

- Inputs include amount/price, down payment, trade-in value, fees, APR, term months,
  and tax rate with vehicle-specific presets.
- Outputs include monthly payment, total interest, total cost, amount financed, and a
  pie or legend chart; amortization tables are available post-token.
- Offer four pre-configured scenarios, responsive layouts, and an embeddable widget
  variant for partner sites.

### APIs and Services

- Provide `GET /api/v1/health` for service checks.
- Provide `POST /api/v1/calculators/<type>` to compute payments and amortization
  schedules.
- Provide `POST /api/v1/leads` to capture submissions, generate tokens, and trigger
  notifications.
- Provide `POST /api/v1/track` to log affiliate and UTM activity.
- Provide `GET /api/v1/partners` to return partner offers (static JSON initially).

### Lead Capture and Token Gating

- Lead form collects first name, last name, email (required), phone (optional with
  +/10-15 digit validation), vehicle type, vehicle price, affiliate, UTMs, IP, and
  user agent.
- Issued tokens gate access to amortization tables and exports; tokens are persisted
  with the lead data for later validation.
- Email notifications alert internal teams when new leads are created (v1 scope).
- CSV exports are available via signed, time-limited links or CLI utilities; no admin
  panel is required in MVP.

### Affiliate Tracking and Analytics

- Accept `aff` and `utm_*` query parameters, persisting them server-side for both
  visits and lead submissions.
- Capture click/visit tracking via `/track` and surface basic counts or CTRs for
  future reporting.

### Persistence

- Migrate from JSON storage to Postgres with Alembic migrations; maintain JSON
  fallback for local development.
- Define tables for leads, quotes, tracks, and partner content; prepare Cloud SQL
  adoption for production.

### Deployment and Operations

- Enforce blue/green deployments with automated smoke tests and health validation.
- Manage secrets via `.env` and CI/CD; prohibit repository secrets.
- Document operations scripts and validate using Caddy in Full (strict) mode.

## Non-Functional Requirements

- **Performance**: Initial paint \< 1 second on broadband; `/api/v1/calculators` p95 \<
  300ms; `/api/quote` legacy endpoints \< 50ms under 100 RPS.
- **Availability**: 99.9% uptime for public endpoints with health monitoring.
- **Data Retention**: Leads retained for 18 months; tracking data for 6 months with
  configurable retention windows.
- **Privacy & Security**: HTTPS in production, consent checkbox with privacy policy,
  IP logging, rate limiting, and zero secrets stored in the repo.
- **Accessibility**: WCAG 2.1 AA compliance for form labels, focus states, and
  contrast ratios.
- **Maintainability**: Modular code, unit tests, linting, and consistent formatting;
  versioned endpoints ease future iterations.

## Success Metrics (MVP Targets)

- Calculator-to-lead conversion ≥ 6% on mobile traffic.
- Lead acceptance rate by partners ≥ 70% of submissions.
- 99.9% uptime for `/api/v1/health` and calculator APIs with p95 amortization latency
  \< 300ms.
- Cost per qualified lead remains within affiliate payout margins.
- Bounce rate \< 45% on organic traffic; zero secrets flagged in CI checks.

## Milestones

1. **API v1 Scaffold**: Establish routers under `/api/v1`, maintain temporary legacy
   endpoints, and update CI with tests and curl examples.
1. **Vehicle Calculator + Amortization**: Implement schedule math with unit tests,
   responsive UI, and token-gated exports.
1. **Postgres Baseline**: Introduce dev Postgres via Compose, create SQLAlchemy models
   (leads, tracks, partners), and generate initial Alembic migration with
   `.env.example` updates.
1. **Lead Capture Enhancements**: Wire server-side UTM capture, email notifications,
   CSV exports, and signed link generation.
1. **Additional Calculators**: Ship mortgage, HELOC, and personal loan calculators
   using shared utilities and add automated regression tests.
1. **Partners API + UI**: Expose partner cards via `/api/v1/partners`, render swipe UI
   modules on the web, and add end-to-end smoke coverage.
1. **Staging & Production Readiness**: Run migrations in CI, enforce smoke tests for
   `/api/v1/*`, validate Caddy configuration, and finalize blue/green deployment docs.

## Risks & Mitigations

- **Scope Creep**: Focus on modular math utilities and incremental release of loan
  types to prevent overextension.
- **Data Migration Complexity**: Start with minimal schema, add migrations
  iteratively, and test backups/rollbacks.
- **Token Abuse & Privacy**: Store minimal PII, rotate tokens, document retention,
  and monitor for suspicious access.
- **Low Conversion**: Experiment with trust signals, minimize required fields, and
  emphasize "no hard pull" messaging.
- **Affiliate Rejection**: Validate email/phone formats, throttle low-quality sources,
  and ensure timely reporting.

## Open Questions

- Do partners require an admin interface in v2 or is JSON configuration sufficient?
- Should amortization exports remain CSV-only in v2 with PDF deferred?
- Will staging mirror Cloud SQL or rely on a managed sandbox database?
- What additional consent language is required for SMS outreach by affiliate or
  dealer partners?
