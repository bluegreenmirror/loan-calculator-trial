# Test Plan

This plan outlines unit and integration tests for the loan quote service.

## Test Execution

- Run `make test` locally before branching or submitting a PR to ensure the suite passes on a clean working tree.
- Optionally run `make verify` for a production-safe gate that layers linting on top of the automated tests.

## Unit Tests

- **Standard calculation** – verifies amount financed, payment, interest, and total cost for typical values.
- **Zero APR** – ensures no interest is charged when the APR is zero.
- **Zero term** – validates handling when the term is zero, returning the principal with no payments.
- **Trade-in exceeds price** – checks principal cannot go negative when trade-in value is higher than price.
- **Negative APR validation** – confirms invalid APR values raise validation errors.

## Integration Tests

- **GET `/api/health`** – returns `{ "ok": true }`.
- **POST `/api/quote`** – returns calculated values for a standard request.
- **POST `/api/quote` with invalid APR** – responds with HTTP `422` for out-of-bound values.

## Future Coverage

- Endpoints for leads and affiliate tracking.
- Front-end interactions and end-to-end scenarios.
