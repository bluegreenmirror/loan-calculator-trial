# Sprint: SEO & Chat Agent Optimization

## Goal

- Elevate organic visibility for `auto loan calculator`, `RV loan calculator`, `motorcycle loan calculator`, and `jet ski loan calculator` queries.
- Expose structured content that AI/chat agents can ingest for accurate summaries and featured answers.

## Acceptance Criteria

- Updated landing page metadata and copy references the targeted vehicle loan calculator keywords naturally.
- Each vehicle type has a dedicated content section with plain-language explanations and comparison points.
- Structured data (FAQ) published in the HTML head or body validates via common schema checkers.
- Internal documentation captures the workstream along with risk assessment and validation steps.

## Tasks

1. Refresh `<head>` metadata to emphasize the primary loan calculator keywords and provide social previews aligned with the new copy.
1. Add SEO-focused content sections covering auto, RV, motorcycle, and jet ski calculators; include keyword-rich headings and supporting paragraphs.
1. Publish FAQPage JSON-LD with answers geared toward AI/chat agents so they can surface canonical guidance.
1. Update styles if needed to keep the new sections on brand and accessible.
1. Document risks, mitigations, and validation steps in the repository.

## Chat Agent Enablement

- Provide a concise `data-chat-summary` block that agents can quote verbatim.
- Supply FAQ entries with explicit prompts and responses for auto/RV loan calculations.
- Ensure copy uses consistent terminology (`vehicle loan calculator`, `auto loan calculator`, etc.) to reduce hallucination risk.

## Risks & Mitigations

| Risk                                                    | Impact                                         | Mitigation                                                                     |
| ------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ |
| Over-optimization could hurt readability or user trust. | Users may bounce if copy feels spammy.         | Keep copy scannable, limit keyword density, provide value-driven explanations. |
| Structured data syntax errors.                          | Search engines ignore FAQ data or flag errors. | Validate JSON-LD via schema validator and automated linting where possible.    |
| Additional sections affect layout on mobile.            | Poor UX on small screens.                      | Test responsive view; adjust CSS breakpoints if spacing breaks.                |

## Validation

- `make lint`
- `pytest`
- `make validate-local`
