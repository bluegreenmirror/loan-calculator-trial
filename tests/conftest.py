import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--run-external",
        action="store_true",
        default=False,
        help="Run tests that require external services like Caddy",
    )


def pytest_configure(config):
    config.addinivalue_line(
        "markers",
        "external: marks tests that require external services (deselect with -m 'not external')",
    )


def pytest_collection_modifyitems(config, items):
    if config.getoption("--run-external"):
        return
    skip_external = pytest.mark.skip(reason="need --run-external option to run")
    for item in items:
        if "external" in item.keywords:
            item.add_marker(skip_external)

