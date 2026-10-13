#!/usr/bin/env bash
# build_image.sh  (run on an INTERNET-connected machine with Docker)
#
# Builds the migration image and saves it to a tar you carry to the air-gap host.
# The base image (python:3.11-slim) is pulled during build, so it is BAKED INTO
# the saved tar -> no registry access needed on the air-gapped server.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

IMAGE="${IMAGE:-cbevmigration:1.0}"
OUT="${OUT:-cbevmigration_image.tar}"

echo "[*] Building $IMAGE ..."
docker build -t "$IMAGE" .

echo "[*] Saving $IMAGE -> $OUT (gzip)"
docker save "$IMAGE" | gzip > "$OUT.gz"

echo ""
echo "[OK] Image saved: $HERE/$OUT.gz"
echo "     Transfer it + the repo (for config) to the air-gap host, then:"
echo "       gunzip -c $OUT.gz | docker load"
echo "       ./run_container.sh migrate 886970007050 --dry-run"
