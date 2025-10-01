from pathlib import Path

from fastapi.testclient import TestClient

from api import app as app_module


def _prepare_static_dir(tmp_path: Path) -> Path:
    static_dir = tmp_path / "static"
    static_dir.mkdir()
    (static_dir / "index.html").write_text("<html><body>Loan Calculator</body></html>")
    (static_dir / "main.js").write_text("console.log('hello');")
    return static_dir


def test_serves_index(monkeypatch, tmp_path):
    static_dir = _prepare_static_dir(tmp_path)
    monkeypatch.setenv("STATIC_ROOT", str(static_dir))
    client = TestClient(app_module.app)

    resp = client.get("/")

    assert resp.status_code == 200
    assert "Loan Calculator" in resp.text


def test_serves_assets_and_spa_fallback(monkeypatch, tmp_path):
    static_dir = _prepare_static_dir(tmp_path)
    monkeypatch.setenv("STATIC_ROOT", str(static_dir))
    client = TestClient(app_module.app)

    asset_resp = client.get("/main.js")
    assert asset_resp.status_code == 200
    assert "hello" in asset_resp.text

    spa_resp = client.get("/quotes/rv")
    assert spa_resp.status_code == 200
    assert "Loan Calculator" in spa_resp.text


def test_api_routes_still_accessible(monkeypatch, tmp_path):
    static_dir = _prepare_static_dir(tmp_path)
    monkeypatch.setenv("STATIC_ROOT", str(static_dir))
    client = TestClient(app_module.app)

    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}
