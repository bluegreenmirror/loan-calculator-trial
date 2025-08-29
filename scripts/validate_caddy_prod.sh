#!/usr/bin/env bash
set -euo pipefail

# Validate production Caddy deployment behavior using curl and openssl.
# Requires env vars: APEX_HOST, WWW_HOST

fail() { echo "[FAIL] $*" >&2; exit 1; }
pass() { echo "[OK] $*"; }

APEX_HOST=${APEX_HOST:-}
WWW_HOST=${WWW_HOST:-}
HSTS_LINE=${HSTS_LINE:-}

[[ -n "$APEX_HOST" ]] || fail "APEX_HOST is required"
[[ -n "$WWW_HOST" ]] || fail "WWW_HOST is required"

echo "Validating Caddy production at apex=$APEX_HOST, www=$WWW_HOST"

# 1) Apex HTTP -> redirect to https://WWW_HOST
code=$(curl -s -o /dev/null -w '%{http_code}' -I "http://$APEX_HOST/") || true
[[ "$code" == "301" || "$code" == "308" ]] || fail "Apex HTTP expected 301/308, got $code"
loc=$(curl -s -I "http://$APEX_HOST/" | awk -v IGNORECASE=1 '/^Location:/ {print $2}' | tr -d '\r')
[[ "$loc" == https://$WWW_HOST/* || "$loc" == https://$WWW_HOST ]] || fail "Apex Location should point to https://$WWW_HOST, got '$loc'"
pass "Apex HTTP redirects to $loc ($code)"

# 2) WWW HTTP -> redirect to HTTPS
code=$(curl -s -o /dev/null -w '%{http_code}' -I "http://$WWW_HOST/") || true
[[ "$code" == "301" || "$code" == "308" ]] || fail "WWW HTTP expected 301/308, got $code"
loc=$(curl -s -I "http://$WWW_HOST/" | awk -v IGNORECASE=1 '/^Location:/ {print $2}' | tr -d '\r')
[[ "$loc" == https://$WWW_HOST/* || "$loc" == https://$WWW_HOST ]] || fail "WWW Location should point to https://$WWW_HOST, got '$loc'"
pass "WWW HTTP redirects to $loc ($code)"

# 3) WWW HTTPS serves HTML with 200
code=$(curl -s -o /dev/null -w '%{http_code}' "https://$WWW_HOST/") || true
[[ "$code" == "200" ]] || fail "HTTPS GET expected 200, got $code"
ctype=$(curl -s -I "https://$WWW_HOST/" | awk -v IGNORECASE=1 '/^Content-Type:/ {print tolower($2)}' | tr -d '\r')
echo "$ctype" | grep -qi 'text/html' || fail "Content-Type should include text/html, got '$ctype'"
pass "WWW HTTPS returns 200 and HTML"

# 4) Optional HSTS header when configured
if [[ -n "${HSTS_LINE}" ]]; then
  hsts=$(curl -s -I "https://$WWW_HOST/" | awk -v IGNORECASE=1 '/^Strict-Transport-Security:/ {print $0}')
  [[ -n "$hsts" ]] || fail "HSTS expected, but not present"
  pass "HSTS header present: $hsts"
else
  echo "HSTS not required (HSTS_LINE not set)"
fi

# 5) TLS is valid (curl will error on invalid cert). Show issuer/dates for visibility.
curl -sSfI "https://$WWW_HOST/" >/dev/null || fail "TLS handshake or HTTP HEAD failed"
if command -v openssl >/dev/null 2>&1; then
  echo "Certificate info (issuer, dates):"
  echo | openssl s_client -servername "$WWW_HOST" -connect "$WWW_HOST:443" 2>/dev/null | openssl x509 -noout -issuer -dates || true
fi
pass "TLS validated by curl"

# 6) Redirect loop safety check (should be 0 after reaching HTTPS root)
loops=$(curl -s -o /dev/null -w '%{num_redirects}' -L "https://$WWW_HOST/")
[[ "$loops" == "0" ]] || fail "Unexpected redirects on HTTPS root (num_redirects=$loops)"
pass "No redirects on HTTPS root"

echo "All production checks passed."

