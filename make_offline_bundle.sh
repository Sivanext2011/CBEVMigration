#!/usr/bin/env bash
# =============================================================================
# make_offline_bundle.sh  (run on an INTERNET-CONNECTED machine)
#
# Produces a single tarball you carry to the air-gapped server. It contains:
#   - the full CBEVMigration repo
#   - wheelhouse/  (all pip wheels incl. transitive deps for requirements.txt)
#   - install_offline.sh / run.sh  (used on the target)
#
# IMPORTANT: download the wheels on a machine that MATCHES the air-gap target's
# Python version, OS and CPU arch. If they differ, set the TARGET_* vars below
# so pip fetches matching manylinux wheels.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$HERE"
OUT="${OUT:-cbevmigration_offline.tgz}"
WHEELHOUSE="$REPO_DIR/wheelhouse"

# ---- Optional cross-download for a different target (leave blank to use THIS machine) ----
# e.g. TARGET_PYVER=3.11  TARGET_PLATFORM=manylinux2014_x86_64
TARGET_PYVER="${TARGET_PYVER:-}"
TARGET_PLATFORM="${TARGET_PLATFORM:-}"

echo "[*] Python: $(python3 --version 2>&1)"
echo "[*] Cleaning old wheelhouse..."
rm -rf "$WHEELHOUSE"
mkdir -p "$WHEELHOUSE"

echo "[*] Downloading wheels for requirements.txt -> $WHEELHOUSE"
DL_ARGS=(download -r "$REPO_DIR/requirements.txt" -d "$WHEELHOUSE")
if [[ -n "$TARGET_PYVER" && -n "$TARGET_PLATFORM" ]]; then
  echo "    (cross-download for py$TARGET_PYVER / $TARGET_PLATFORM)"
  DL_ARGS+=(--only-binary=:all: --python-version "$TARGET_PYVER" --platform "$TARGET_PLATFORM")
fi
python3 -m pip "${DL_ARGS[@]}"

# also vendor pip/setuptools/wheel so the target can bootstrap without internet
echo "[*] Adding pip/setuptools/wheel to the wheelhouse (bootstrap)"
python3 -m pip download pip setuptools wheel -d "$WHEELHOUSE" >/dev/null 2>&1 || \
  echo "    (skipped pip bootstrap download; target likely already has pip)"

echo "[*] Wheels collected:"
ls -1 "$WHEELHOUSE" | sed 's/^/      /'

# ---- Build the tarball (exclude venvs, caches, git internals optional) ----
STAGE="$(mktemp -d)"
PKG="$STAGE/CBEVMigration"
echo "[*] Staging repo -> $PKG"
mkdir -p "$PKG"
# copy repo contents (keep wheelhouse, scripts, config, migration, etc.)
tar -C "$REPO_DIR" \
    --exclude='.venv' --exclude='__pycache__' --exclude='.pytest_cache' \
    --exclude='*.pyc' --exclude='e2e_state.db' --exclude='*.html' \
    -cf - . | tar -C "$PKG" -xf -

echo "[*] Creating $OUT"
tar -C "$STAGE" -czf "$REPO_DIR/$OUT" CBEVMigration
rm -rf "$STAGE"

echo ""
echo "[OK] Offline bundle ready: $REPO_DIR/$OUT"
echo "     Transfer it to the air-gapped server, then:"
echo "       tar xzf $OUT && cd CBEVMigration && ./install_offline.sh"
