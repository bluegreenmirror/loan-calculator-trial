# Sprint 1: SEO & Chat Agent Optimization

## Goal

- Elevate organic visibility for `auto loan calculator`, `RV loan calculator`, `motorcycle loan calculator`, and `jet ski loan calculator` queries.
- Expose structured content that AI/chat agents can ingest for accurate summaries and featured answers.

## Acceptance Criteria

- Updated landing page metadata and copy references the targeted vehicle loan calculator keywords naturally.
- Each vehicle type has a dedicated content section with plain-language explanations and comparison points.
- Structured data (FAQ) published in the HTML head or body validates via common schema checkers.
- Internal documentation captures the workstream along with risk assessment and validation steps.

## Tasks Overview

The authoritative sprint backlog now lives in `sprints/sprint-1.json`. That file tracks task identifiers, status, and notes.

| Ticket | Task                                              | Status   | Notes                                                                                     |
| ------ | ------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------- |
| s1-t1  | Refresh `<head>` metadata                         | Complete | Highlights the primary calculator keywords and refreshed previews.                        |
| s1-t2  | Add SEO-focused content sections                  | Complete | Vehicle-specific sections cover auto, RV, motorcycle, and jet ski calculators.            |
| s1-t3  | Publish FAQPage JSON-LD                           | Complete | Chat-oriented answers exposed via structured data.                                        |
| s1-t4  | Update supporting styles                          | Complete | Ensures the expanded sections remain accessible and on brand.                             |
| s1-t5  | Document risks, mitigations, and validation steps | Complete | Finalized guidance covering risk scenarios, accountable owners, and validation playbooks. |

## Guidelines

- Shared sprint guardrails are documented in `sprints.json`.
- Cap each sprint at ten tickets; create a new sprint once additional work would exceed the cap.
- Keep tickets small, atomic, and as independent as possible to enable smooth sequencing and ownership.

## Progress Summary

- Updated landing page metadata now highlights auto, RV, motorcycle, and jet ski loan calculator keywords alongside refreshed social previews. (`web/dist/index.html`)
- Vehicle-specific SEO content, chat agent briefing notes, and FAQ entries are live on the landing page to support organic and conversational discovery. (`web/dist/index.html`)
- FAQPage JSON-LD answers and supporting styles for the new sections ship with the build, ensuring structured data validation and consistent presentation. (`web/dist/index.html`, `web/dist/style.css`)
- Risk, mitigation, and validation documentation has been published, giving delivery and operations teams clear owners and follow-up actions to maintain the sprint outcomes. (`docs/sprints/1-seo-chat.md`)

## Chat Agent Enablement

- Provide a concise `data-chat-summary` block that agents can quote verbatim.
- Supply FAQ entries with explicit prompts and responses for auto/RV loan calculations.
- Ensure copy uses consistent terminology (`vehicle loan calculator`, `auto loan calculator`, etc.) to reduce hallucination risk.

## Risks & Mitigations

| Risk                                                    | Impact                                         | Mitigation                                                                                                                                                                       |
| ------------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Over-optimization could hurt readability or user trust. | Users may bounce if copy feels spammy.         | Content owner reviews each sprint update for plain-language tone before release; marketing lead spot-checks post-launch metrics for bounce spikes and rolls back copy if needed. |
| Structured data syntax errors.                          | Search engines ignore FAQ data or flag errors. | Build step runs `npm run lint:structured-data`; release manager validates FAQ JSON-LD via schema.dev and Search Console rich-result testing before deploy approval.              |
| Additional sections affect layout on mobile.            | Poor UX on small screens.                      | QA lead validates responsive layouts at 320px, 768px, and 1024px breakpoints; regressions generate follow-up CSS fixes prior to release.                                         |
| Data or rate changes render published answers stale.    | Chat agents serve outdated terms or guidance.  | Product owner schedules quarterly content reviews and coordinates with finance to refresh rate assumptions; publish updates via the standard release checklist.                  |

## Validation

1. Run `make lint` and `pytest` to confirm build health before publishing documentation updates.
1. Execute `make validate-local` to ensure structured data and page metadata still satisfy automated checks after content edits.
1. Re-run the FAQ schema through schema.dev or Google’s Rich Result test and archive the validation screenshot in the sprint folder.
1. Perform manual responsive checks at the documented breakpoints to confirm no regressions slipped past automation.
