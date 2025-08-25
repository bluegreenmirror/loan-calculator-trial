# loan-calculator-trial

## CORS configuration

The API exposes configuration for cross-origin requests via the
`ALLOWED_ORIGINS` environment variable. Set this to a comma-separated list of
origins that are permitted to access the API (for example,
`ALLOWED_ORIGINS="https://example.com,http://localhost:8080"`).

If `ALLOWED_ORIGINS` is not provided, cross-origin requests will be blocked by
default to reduce the risk of malicious sites interacting with the service.

