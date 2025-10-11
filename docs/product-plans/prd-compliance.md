# Sprint 2: PRD Compliance Hardening

## Goal

- Close the outstanding MVP gaps so the vehicle loan calculator implements every functional requirement from the base PRD.
- Align frontend and backend behaviors so future presets or asset types can reuse a single source of truth.

## Remaining PRD Gaps

- The PRD calls for trade-in value and tax rate inputs alongside price, fees, down payment, APR, and term, but the current UI only exposes price, APR, term, down payment, and fees. 【F:docs/PRD.md†L23-L31】【F:web/dist/index.html†L33-L88】
- `/api/quote` already supports trade-in and tax math, yet the frontend performs its own calculations and never invokes the API, so the shipped experience diverges from the documented contract. 【F:docs/PRD.md†L37-L49】【F:api/app.py†L35-L93】【F:web/dist/app.js†L55-L123】
- Affiliate tracking must persist UTM parameters and affiliate IDs according to the PRD, but only the affiliate ID is posted today and UTMs are dropped. 【F:docs/PRD.md†L50-L63】【F:web/dist/app.js†L1-L53】【F:api/app.py†L111-L159】

## Acceptance Criteria

- Calculator UI exposes price, down payment, trade-in value, fees, tax rate, APR, and term inputs with validation.
- Frontend consumes the `/api/quote` endpoint so business logic lives in one place and honors trade-in and tax fields.
- Affiliate and UTM metadata are persisted for both click tracking and submitted leads.
- Automated tests cover the new quote, lead, and tracking scenarios.

## Tasks Overview

Detailed ticket tracking for this sprint lives in `sprints/sprint-2.json`.

| Ticket | Task                                                  | Status | Notes                                                                                            |
| ------ | ----------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------ |
| s2-t1  | Add trade-in and tax rate inputs to the calculator    | Todo   | Surface the remaining PRD inputs with inline validation and formatting.                          |
| s2-t2  | Call `/api/quote` from the frontend calculator        | Todo   | Send the full payload (price, fees, down, trade-in, tax, APR, term) and render the API response. |
| s2-t3  | Persist UTM parameters when tracking affiliate clicks | Todo   | Include `utm_*` values in `/api/track` requests and store them alongside the affiliate ID.       |
| s2-t4  | Attach affiliate and UTM metadata to lead submissions | Todo   | Send stored affiliate and UTM values with `/api/leads` and persist them server-side.             |
| s2-t5  | Extend API tests for quote, track, and lead flows     | Todo   | Add pytest coverage for trade-in/tax math plus metadata persistence.                             |

## Dependencies & Risks

- Frontend changes depend on the API accepting and responding with the expanded payload, so testing should run against the same build artifacts that ship.
- Persisting metadata increases the size of stored JSON; we need to confirm `/data` volumes have sufficient space and are rotated as part of ops hygiene.

## Validation

- `pytest`
- `make lint`
- Manual smoke test of calculator UI plus lead and tracking submissions.
