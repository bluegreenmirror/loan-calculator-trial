#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--build|-b] [--pull] [--prune] [--verify] [--bootstrap]

Options:
  -b, --build     Build Docker images before deploying
      --pull      Pull latest base images before building
      --prune     Prune dangling Docker images after deploy
      --verify    Run linters/tests via Makefile (requires Python venv/dev tools)
      --bootstrap Install server prerequisites (Docker, Compose, make, Python venv)
EOF
}

BUILD=0; PULL=0; PRUNE=0; VERIFY=0; BOOTSTRAP=0
for arg in "$@"; do
  case "$arg" in
    -b|--build) BUILD=1 ;; 
    --pull)     PULL=1 ;; 
    --prune)    PRUNE=1 ;; 
    --verify)   VERIFY=1 ;; 
    --bootstrap) BOOTSTRAP=1 ;; 
    -h|--help)  usage; exit 0 ;; 
  esac
done

if [ ! -f ".env" ]; then
  echo "Missing .env. Create it with DOMAIN and EMAIL."; exit 1
fi

if [ $BOOTSTRAP -eq 1 ]; then
  echo "Bootstrapping server prerequisites..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker.io docker-compose-plugin make python3-venv python3-pip
    # Ensure docker group exists and add current user
    if ! getent group docker >/dev/null 2>&1; then
      sudo groupadd docker || true
    fi
    sudo usermod -aG docker "$USER" || true
    echo "Bootstrap complete. If this is your first time installing Docker, log out and back in (or run: newgrp docker) before continuing."
  else
    echo "Unsupported package manager. Please install Docker, docker-compose-plugin, make, and Python (venv) manually."
  fi
fi

# Choose docker command (fallback to sudo if needed)
DOCKER_CMD="docker"
if ! $DOCKER_CMD ps >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1;
    then
    DOCKER_CMD="sudo docker"
  fi
fi

if [ $PULL -eq 1 ]; then
  $DOCKER_CMD compose pull
fi

ensure_venv_and_deps() {
  echo "Ensuring virtual environment and dependencies..."
  if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
    if [ ! -d ".venv" ]; then
      echo "Failed to create virtual environment."; exit 1
    fi
  fi
  . .venv/bin/activate
  pip install --upgrade pip
  if [ -f requirements-dev.txt ]; then
    echo "Installing dependencies from requirements-dev.txt..."
    pip install -r requirements-dev.txt
  fi
  if ! command -v ruff >/dev/null 2>&1; then
    echo "ruff not found in virtual environment."; exit 1
  fi
  echo "Virtual environment and dependencies are up to date."
}

if [ $BUILD -eq 1 ]; then
  if [ $VERIFY -eq 1 ]; then
    if ! command -v make >/dev/null 2>&1; then
      echo "make is required for --verify. Install it or re-run without --verify."; exit 1
    fi
    ensure_venv_and_deps
    make verify
  else
    echo "Skipping verification (linters/tests). Use --verify to enable."
  fi
  $DOCKER_CMD compose build --pull
fi

# Start or update containers
if ! DockerComposeUpOutput=$($DOCKER_CMD compose up -d 2>&1); then
  echo "$DockerComposeUpOutput"
  exit 1
fi

domain=$(grep ^DOMAIN .env | cut -d= -f2)
echo "Waiting for Caddy at http://$domain ..."
for i in {1..20}; do
  if curl -sSf -o /dev/null http://$domain; then
    echo "Caddy is up."
    break
  fi
  sleep 1
done

# Run lint and tests after services are up so Caddy health test passes
make verify

if [ $PRUNE -eq 1 ]; then
  $DOCKER_CMD image prune -f
fi

echo "Deployed. Checking health..."
sleep 5
domain=$(grep ^DOMAIN .env | cut -d= -f2)
status=$(curl -Is http://$domain | head -n 1 | sed 's/\r$//')
echo "$status"