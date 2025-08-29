import os
import requests
import pytest


@pytest.mark.external
def test_caddy_health():

    """Tests that the Caddy server (external) is running and accessible.

    Uses HEAD request against CADDY_HEALTH_URL (defaults to http://localhost).
    """
    url = os.getenv("CADDY_HEALTH_URL", "http://localhost")
    resp = requests.head(url, timeout=2)
    assert resp.status_code in {200, 301, 302, 308}