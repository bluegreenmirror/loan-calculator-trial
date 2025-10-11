# SECURITY_PRIVACY.md

## Controls

- TLS via Caddy and Let's Encrypt.
- Secrets only in environment variables or CI secrets.
- Validation for emails, phone numbers and numeric ranges.
- Basic IP-based rate limit for write endpoints.
- Log redaction for PII where possible.

## Privacy

- Consent checkbox with reference to Privacy Policy.
- Data retention: Leads 18 months, Tracks 6 months.
- Right to delete requests handled via support email.

## Compliance

- TCPA-friendly wording if SMS/phone outreach is planned by partners.
