# Loan Calculator Platform v2 PRD

## Overview

The v2 release focuses on making the loan calculator platform modular and mobile-
ready. Each calculator is hosted on its own path under `vibesforce.com` and
exposes APIs that can be reused by web and mobile clients.

## Goals

- Provide vehicle, mortgage, HELOC, and personal loan calculators.
- Generate monthly amortization schedules for all loan types.
- Serve calculators as embeddable components and REST APIs.
- Introduce a swipe-based Partners & Products page for affiliate offers.
- Migrate data storage to Google Cloud SQL.
- Gate amortization schedules and exports behind email capture for lead
  generation and future verification.

## User Stories

- **Borrower** wants to compare loan options and view monthly payments.
- **Affiliate marketer** wants to display partner offers to users.
- **Mobile developer** wants to embed calculators inside native apps.

## Functional Requirements

1. Calculators accept loan amount, term, interest rate, and related inputs.
1. API returns monthly amortization schedule with principal and interest break-
   down.
1. Partners page shows swipeable cards with key offer details.
1. All calculators and partners API endpoints are versioned under `/api/v1/`.
1. Data is stored in Cloud SQL with migration scripts.
1. Viewing amortization schedules or exports requires users to submit an
   email address.
1. Captured emails are stored as leads and can be verified later to ensure
   legitimate users.

## Non-functional Requirements

- Responsive UI for desktop and mobile web.
- API latency under 300 ms for typical calculations.
- Code and documentation linted and formatted per repo guidelines.
