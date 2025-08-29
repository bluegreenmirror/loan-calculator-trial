#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <version> [--push] [--verify]

Creates an annotated git tag for a release and (optionally) pushes it.

Arguments:
  <version>   Version string, e.g. v0.1.0 (must start with 'v')

Options:
  --push      Push the tag to origin
  --verify    Run 'make verify' before tagging (requires dev deps)

Examples:
  $0 v0.1.0 --verify --push
EOF
}

if [[ $# -lt 1 ]]; then usage; exit 1; fi

VERSION="$1"; shift || true
PUSH=0; VERIFY=0
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    --verify) VERIFY=1 ;;
    -h|--help) usage; exit 0 ;;
  esac
done

[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Version must look like vX.Y.Z"; exit 1; }

# Ensure clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has changes. Commit or stash before tagging."; exit 1
fi

if [[ $VERIFY -eq 1 ]]; then
  if command -v make >/dev/null 2>&1; then
    make verify
  else
    echo "make not found; skipping verify. Re-run with make installed or omit --verify."; exit 1
  fi
fi

# Create annotated tag
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "Tag $VERSION already exists."; exit 1
fi

git tag -a "$VERSION" -m "Release $VERSION"
echo "Created tag $VERSION"

if [[ $PUSH -eq 1 ]]; then
  git push origin "$VERSION"
  echo "Pushed tag $VERSION to origin"
fi

echo "Done. Deploy with: git checkout $VERSION && ./deploy.sh -b --verify"

