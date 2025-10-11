# ANALYTICS_METRICS.md

## Events

- `quote.view` with vehicle_type
- `quote.compute` with inputs bucketed (price band), success flag
- `lead.submit` with vehicle_type, affiliate, utm_source
- `affiliate.click` with affiliate and utm tags

## Funnel

1. Landing
1. Compute quote
1. Lead modal open
1. Lead submit

## KPIs

- Conversion rate (lead submits / sessions)
- Cost per lead (ad spend / leads)
- Lead acceptance by partner
- Time to first response (if email notifications enabled)

## Storage

- Server-side events in Postgres.
- Retention: raw tracking 6 months; aggregates indefinite.
