# Loan Calculator — Product Requirements Document (PRD)

## Vision
Provide a **fast, responsive, and extensible loan calculator** that can generate monthly payment estimates for different vehicle types (autos, RVs, motorcycles, jet skis). Monetize the calculator through **affiliate partnerships**, **lead-generation forms**, and **API access for dealerships**.

## Goals
- **Core MVP**: Clean UI loan calculator, responsive and mobile-first.
- **Extensibility**: Support new asset types with minimal code changes.
- **Monetization**: Affiliate link integration and lead form capture.
- **APIs**: Secure, developer-friendly endpoints for dealerships to integrate.
- **Deployment**: Fully containerized, cloud-ready with auto-SSL.

## Target Users
- **Consumers**: People looking to estimate vehicle loan payments.
- **Dealerships / Lenders**: Organizations embedding calculators and collecting leads.
- **Affiliates**: Partners driving traffic via referral/UTM links.

## Functional Requirements
1. **Frontend Calculator**
   - Input: Price, down payment, trade-in, fees, tax rate, APR, term.
   - Presets: Auto, RV, Motorcycle, Jet Ski (APR + default terms).
   - Output: Monthly payment, amount financed, total cost, total interest.
   - Lead form: Name, email, phone, vehicle type, affiliate code (hidden).
   - Tracking: Capture UTM params and affiliate IDs.

2. **Backend API**
   - `/api/health`: service health.
   - `/api/quote`: compute financing details.
   - `/api/leads`: save posted leads (JSON or DB).
   - `/api/track`: log affiliate clicks with timestamp.

3. **Affiliate Integration**
   - Affiliate IDs passed via URL (e.g. `?aff=partnerX`).
   - Tracking stored on backend.
   - Links updated dynamically in UI.

4. **Lead Gen**
   - Form submission → API → stored with metadata (affiliate, timestamp).
   - Optional email notifications (future scope).

5. **Deployment**
   - Docker Compose stack: `caddy` (reverse proxy), `web` (static), `api` (FastAPI).
   - Caddy handles TLS in prod, auto-HTTPS disabled in dev.
   - Configurable via `.env` (`ADDR`, `TLS_DIRECTIVE`, etc.).

## Non-Functional Requirements
- **Performance**: Page loads in <1s on broadband.
- **Scalability**: API horizontally scalable.
- **Security**: TLS in prod, input validation on API.
- **Maintainability**: Clear contribution guidelines, modular design.

## Future Scope
- Support additional asset classes (boats, heavy equipment).
- Lead export (CSV, Google Sheets integration).
- Dealership dashboard (analytics, conversion tracking).
- Multi-language support.