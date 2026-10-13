#!/usr/bin/env bash
# =============================================================================
# install_offline.sh  (run on the AIR-GAPPED server, inside the extracted repo)
#
# Installs the tool's dependencies purely from ./wheelhouse (no internet).
# Creates a .venv by default; set NO_VENV=1 to install into the current python.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
WHEELHOUSE="$HERE/wheelhouse"

if [[ ! -d "$WHEELHOUSE" ]]; then
  echo "[ERR] wheelhouse/ not found. Did you extract the full offline bundle?" >&2
  exit 1
fi

# pick a python (prefer 3.11+)
PY="${PYTHON:-}"
if [[ -z "$PY" ]]; then
  for c in python3.11 python3.12 python3 python; do
    if command -v "$c" >/dev/null 2>&1; then PY="$c"; break; fi
  done
fi
[[ -n "$PY" ]] || { echo "[ERR] No python found. Install Python 3.11+ first." >&2; exit 1; }
echo "[*] Using: $($PY --version 2>&1)  ($PY)"

PIP_OFFLINE=(-m pip install --no-index --find-links="$WHEELHOUSE")

if [[ "${NO_VENV:-0}" == "1" ]]; then
  echo "[*] Installing into current environment (NO_VENV=1)"
  "$PY" "${PIP_OFFLINE[@]}" -r requirements.txt
  TARGET_PY="$PY"
else
  echo "[*] Creating virtualenv .venv"
  "$PY" -m venv .venv || { echo "[ERR] venv creation failed (python3-venv missing?)." >&2; exit 1; }
  # shellcheck disable=SC1091
  if [[ -f .venv/bin/activate ]]; then source .venv/bin/activate; else source .venv/Scripts/activate; fi
  # bootstrap pip/setuptools/wheel offline if available in wheelhouse
  python -m pip "${PIP_OFFLINE[@]:1}" --upgrade pip setuptools wheel 2>/dev/null || true
  echo "[*] Installing requirements from wheelhouse (offline)"
  python -m pip install --no-index --find-links="$WHEELHOUSE" -r requirements.txt
  TARGET_PY="python"
fi

echo ""
echo "[*] Verifying imports..."
"$TARGET_PY" - <<'PY'
import httpx, httpx_socks, openpyxl
import migration.cli, migration.mapping_engine, migration.bssf_migrator
print("  deps + migration package import OK")
PY

echo ""
echo "[OK] Install complete."
echo "     Activate venv:   source .venv/bin/activate   (skip if NO_VENV=1)"
echo "     Edit configs:"
echo "       config/config.json                      (CBEV env/auth/tls)"
echo "       migration/config/migration_config.json  (AIR UCIP endpoint/creds)"
echo "     Run:             ./run.sh --help    OR    python -m migration.cli --help"
