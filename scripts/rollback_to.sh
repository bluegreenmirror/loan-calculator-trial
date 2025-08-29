#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <git-ref> [--build] [--verify] [--yes]

Checks out a specific git ref (tag or commit) and redeploys.

Arguments:
  <git-ref>   Git tag (e.g., v0.1.0) or commit SHA

Options:
  --build     Rebuild images before starting (maps to deploy.sh -b)
  --verify    Run linters/tests during build (maps to deploy.sh --verify)
  --yes       Non-interactive mode (skip confirmation prompt)

Examples:
  $0 v0.1.0 --build --verify --yes
EOF
}

if [[ $# -lt 1 ]]; then usage; exit 1; fi

REF="$1"; shift || true
BUILD=0; VERIFY=0; YES=0
for arg in "$@"; do
  case "$arg" in
    --build)  BUILD=1 ;;
    --verify) VERIFY=1 ;;
    --yes)    YES=1 ;;
    -h|--help) usage; exit 0 ;;
  esac
done

# Ensure git ref exists locally or fetch tags
if ! git rev-parse --verify --quiet "$REF" >/dev/null; then
  echo "Ref '$REF' not found locally. Fetching tags..."
  git fetch --tags --all --prune
  git rev-parse --verify --quiet "$REF" >/dev/null || { echo "Ref '$REF' not found after fetch."; exit 1; }
fi

if [[ $YES -eq 0 ]]; then
  read -r -p "Checkout '$REF' and redeploy? This will change the working tree. [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# Ensure no uncommitted changes to avoid accidental loss
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has changes. Commit/stash before rollback."; exit 1
fi

git checkout "$REF"
echo "Checked out $(git rev-parse --short HEAD) for ref $REF"

ARGS=()
[[ $BUILD -eq 1 ]] && ARGS+=("-b")
[[ $VERIFY -eq 1 ]] && ARGS+=("--verify")

./deploy.sh "${ARGS[@]}"

echo "Rollback to $REF complete."

