#!/bin/bash
# Build demo domain image
# Usage: ./build.sh [tag] [--no-cache]
set -e
cd "$(dirname "$0")"
TAG="${1:-latest}"; EXTRA=""; [ "$2" = "--no-cache" ] && EXTRA="--no-cache"
docker build -t "demo:${TAG}" $EXTRA .
echo "  ✓ demo:${TAG}"
