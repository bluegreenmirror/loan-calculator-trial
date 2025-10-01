# DATA_MODEL.md

## Entities

- Lead: contact and context for a financing request.
- Quote: computed loan values associated with an input set.
- TrackEvent: click/visit/affiliate tagging record.

## Postgres Tables

- `leads`
- `quotes`
- `tracks`

## Relationships

- A lead may have 0..n quotes.
- A track event may link to a lead via `lead_id` after submission.

## Indexing

- `leads(created_at)`, `leads(vehicle_type)`, `tracks(affiliate, created_at)`
- Partial index: `leads(accepted) WHERE accepted = true` (future).

## ASCII ERD

```
Lead (id) ---< Quote (id)
  ^
  |
  +--- TrackEvent (id) (optional link via lead_id)
```
