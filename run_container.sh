#!/usr/bin/env bash
# run_container.sh  (run on the AIR-GAPPED host, from the repo dir)
#
# Runs the migration CLI inside the container with the live config/certs mounted
# and host networking (so it can reach AIR + CBEV). Loads the image tar on first
# use if the image isn't present yet.
#
# Examples:
#   ./run_container.sh --help
#   ./run_container.sh migrate 886970007050 --dry-run
#   ./run_container.sh batch /app/data/msisdns.txt     # see DATA_DIR below
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

IMAGE="${IMAGE:-cbevmigration:1.0}"
IMAGE_TAR="${IMAGE_TAR:-cbevmigration_image.tar.gz}"
# Host dir holding the TLS certs referenced by config/config.json (tls.*_path).
# Mounted read-only at the SAME path inside the container so the paths resolve.
CERTS_DIR="${CERTS_DIR:-$HERE/config/certs}"
# Optional host dir for inputs/outputs (msisdn files, HTML reports) -> /app/data
DATA_DIR="${DATA_DIR:-$HERE/data}"

# load image if missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  if [[ -f "$IMAGE_TAR" ]]; then
    echo "[*] Loading image from $IMAGE_TAR ..."
    gunzip -c "$IMAGE_TAR" | docker load
  else
    echo "[ERR] Image $IMAGE not loaded and $IMAGE_TAR not found." >&2
    echo "      Run build_image.sh on an online host, copy the tar here." >&2
    exit 1
  fi
fi

mkdir -p "$DATA_DIR"

MOUNTS=(
  -v "$HERE/config/config.json:/app/config/config.json:ro"
  -v "$HERE/migration/config/migration_config.json:/app/migration/config/migration_config.json:ro"
  -v "$DATA_DIR:/app/data"
)
# mount certs at the path the config expects (default repo/config/certs)
if [[ -d "$CERTS_DIR" ]]; then
  MOUNTS+=(-v "$CERTS_DIR:$CERTS_DIR:ro")
fi

# --network host so the tool can reach AIR / CBEV / SOCKS exactly as the host does
exec docker run --rm -it --network host "${MOUNTS[@]}" "$IMAGE" "$@"
