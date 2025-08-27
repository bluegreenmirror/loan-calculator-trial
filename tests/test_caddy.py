import subprocess


def test_caddy_health():
    """Tests that the Caddy server is running and accessible."""
    result = subprocess.run(
        ["curl", "-I", "http://localhost"], capture_output=True, text=True
    )
    assert result.returncode == 0
    assert "HTTP/" in result.stdout and (" 200" in result.stdout or " 301" in result.stdout)
