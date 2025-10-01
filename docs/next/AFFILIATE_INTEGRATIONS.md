# AFFILIATE_INTEGRATIONS.md

## Patterns

- Simple link-out with affiliate ID.
- Server-to-server post of lead data upon `lead.submit`.
- Webhook callbacks for status updates (if offered by partner).

## Required Fields (typical)

- Name, email, optional phone, vehicle type, price.
- Campaign tags: affiliate, utm_source, utm_medium, utm_campaign.

## Mapping

- Maintain per-partner adapter to transform our lead JSON into partner format.

## Safety

- Only send after consent; store partner response id; retry with backoff.
