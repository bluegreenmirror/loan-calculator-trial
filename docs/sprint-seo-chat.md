# Sprint sprint-1: SEO & Chat Agent Optimization

## Goal

- Elevate organic visibility for `auto loan calculator`, `RV loan calculator`, `motorcycle loan calculator`, and `jet ski loan calculator` queries.
- Expose structured content that AI/chat agents can ingest for accurate summaries and featured answers.

## Acceptance Criteria

- Updated landing page metadata and copy references the targeted vehicle loan calculator keywords naturally.
- Each vehicle type has a dedicated content section with plain-language explanations and comparison points.
- Structured data (FAQ) published in the HTML head or body validates via common schema checkers.
- Internal documentation captures the workstream along with risk assessment and validation steps.

## Tasks Overview

The authoritative sprint backlog now lives in `docs/sprint-seo-chat.json`. That file tracks task identifiers, status, and notes.

| Ticket | Task                                              | Status      | Notes                                                                          |
| ------ | ------------------------------------------------- | ----------- | ------------------------------------------------------------------------------ |
| s1-t1  | Refresh `<head>` metadata                         | Complete    | Highlights the primary calculator keywords and refreshed previews.             |
| s1-t2  | Add SEO-focused content sections                  | Complete    | Vehicle-specific sections cover auto, RV, motorcycle, and jet ski calculators. |
| s1-t3  | Publish FAQPage JSON-LD                           | Complete    | Chat-oriented answers exposed via structured data.                             |
| s1-t4  | Update supporting styles                          | Complete    | Ensures the expanded sections remain accessible and on brand.                  |
| s1-t5  | Document risks, mitigations, and validation steps | In progress | Draft documentation outstanding.                                               |

## Guidelines

- Cap each sprint at ten tickets; create a new sprint once additional work would exceed the cap.
- Keep tickets small, atomic, and as independent as possible to enable smooth sequencing and ownership.

## Progress Summary

- Updated landing page metadata now highlights auto, RV, motorcycle, and jet ski loan calculator keywords alongside refreshed social previews. (`web/dist/index.html`)
- Vehicle-specific SEO content, chat agent briefing notes, and FAQ entries are live on the landing page to support organic and conversational discovery. (`web/dist/index.html`)
- FAQPage JSON-LD answers and supporting styles for the new sections ship with the build, ensuring structured data validation and consistent presentation. (`web/dist/index.html`, `web/dist/style.css`)
- Dedicated documentation capturing risks, mitigations, and validation steps still needs to be authored, so task s1-t5 remains outstanding.

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
