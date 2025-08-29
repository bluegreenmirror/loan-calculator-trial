#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--env <blue|green>]

Options:
  --env <blue|green>  Specify the deployment environment (defaults to blue)
EOF
}

ENV="blue"
if [ $# -gt 0 ]; then
  if [ "$1" == "--env" ]; then
    ENV=$2
  else
    usage
    exit 1
  fi
fi

./deploy-blue-green.sh $ENV