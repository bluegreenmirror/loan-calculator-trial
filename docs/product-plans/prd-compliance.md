# Sprint 2: PRD Compliance Hardening

## Goal

- Close the outstanding MVP gaps so the vehicle loan calculator implements every functional requirement from the base PRD.
- Align frontend and backend behaviors so future presets or asset types can reuse a single source of truth.

## PRD Gaps Addressed

- Calculator UI now exposes trade-in value and tax rate inputs alongside price, down payment, fees, APR, and term. 【F:docs/PRD.md†L23-L31】【F:web/dist/index.html†L33-L110】
- The frontend calls `/api/quote` so amount financed, payment, and interest reflect the server calculation that already handles trade-in value and tax rate. 【F:docs/PRD.md†L37-L49】【F:api/app.py†L35-L93】【F:web/dist/app.js†L124-L211】
- Affiliate tracking and lead capture persist UTM metadata together with the affiliate identifier to align with the PRD. 【F:docs/PRD.md†L50-L63】【F:web/dist/app.js†L1-L115】【F:api/app.py†L111-L159】

## Acceptance Criteria

- Calculator UI exposes price, down payment, trade-in value, fees, tax rate, APR, and term inputs with validation.
- Frontend consumes the `/api/quote` endpoint so business logic lives in one place and honors trade-in and tax fields.
- Affiliate and UTM metadata are persisted for both click tracking and submitted leads.
- Automated tests cover the new quote, lead, and tracking scenarios.

## Tasks Overview

Detailed ticket tracking for this sprint lives in `sprints/sprint-2.json`.

| Ticket | Task                                                  | Status | Notes                                                                                            |
| ------ | ----------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------ |
| s2-t1  | Add trade-in and tax rate inputs to the calculator    | Complete | Trade-in value and tax rate fields are live with inline validation alongside existing inputs.     |
| s2-t2  | Call `/api/quote` from the frontend calculator        | Complete | Calculator now uses `/api/quote` and renders the server totals for financed amount and payments. |
| s2-t3  | Persist UTM parameters when tracking affiliate clicks | Complete | `/api/track` receives affiliate plus stored UTM parameters for every captured click.             |
| s2-t4  | Attach affiliate and UTM metadata to lead submissions | Complete | Lead submissions include affiliate and UTM metadata that persist in `leads.json`.                 |
| s2-t5  | Extend API tests for quote, track, and lead flows     | Complete | Pytest coverage verifies trade-in/tax math plus attribution persistence for leads and tracking.  |

## Dependencies & Risks

- Frontend changes depend on the API accepting and responding with the expanded payload, so testing should run against the same build artifacts that ship.
- Persisting metadata increases the size of stored JSON; we need to confirm `/data` volumes have sufficient space and are rotated as part of ops hygiene.

## Validation

- `pytest`
- `make lint`
- Manual smoke test of calculator UI plus lead and tracking submissions.
