# Release Plan for Loan Calculator Platform v2

## Milestones

1. **MVP Calculators**
   - Target: End of Sprint 1
   - Deliver vehicle, mortgage, HELOC, and personal calculators with basic UI.
1. **Amortization & Cloud SQL**
   - Target: End of Sprint 2
   - Include monthly amortization, exports gated by email capture, and Cloud SQL
     migration.
1. **Partners & Products Page**
   - Target: End of Sprint 3
   - Swipe interface available with partner data.
1. **Email Verification**
   - Target: Post-Partners release
   - Validate captured emails to confirm legitimate leads.

## Deployment Steps

1. Run database migrations on Cloud SQL.
1. Build and push Docker images to registry.
1. Deploy services to Cloud Run.
1. Invalidate CDN cache for updated static assets.
1. Smoke test calculators and partners page in production.

## Rollback Strategy

- Maintain previous container image tags.
- Restore database from latest backup if migrations fail.
