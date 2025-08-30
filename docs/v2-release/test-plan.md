# Test Plan for Loan Calculator Platform v2

## Objectives

Ensure calculators produce correct amortization schedules and partners page works
across devices.

## Test Areas

1. **Unit Tests**
   - Calculation functions for each loan type.
   - Database access layers.
1. **API Tests**
   - `/api/v1/calculators/<type>` returns expected JSON.
   - `/api/v1/partners` returns valid card data.
   - `/api/v1/leads` stores email and issues access token.
   - Calculators reject amortization or export requests without a valid token.
1. **UI Tests**
   - Responsive layout for calculators and swipe page.
   - Swipe gestures perform accept/dismiss actions.
   - Amortization and export features prompt for email and unlock after
     submission.
1. **Performance Tests**
   - API responses within 300 ms under normal load.
1. **Regression**
   - Existing v1 features remain functional.

## Tools

- Pytest for unit and API tests.
- Playwright for end-to-end browser tests.
- Locust for performance testing.
