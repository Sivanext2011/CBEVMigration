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

# Decide install mode. venv needs ensurepip/python3-venv which is often missing
# on air-gapped Debian/Ubuntu. If NO_VENV=1, or venv can't be created, fall back
# to a --user install into the system python (no root, no internet).
_try_venv() {
  "$PY" -m venv .venv >/dev/null 2>&1
}

MODE=""
if [[ "${NO_VENV:-0}" == "1" ]]; then
  MODE="user"
elif _try_venv; then
  MODE="venv"
else
  echo "[!] venv unavailable (python3-venv/ensurepip missing). Falling back to --user install."
  MODE="user"
fi

if [[ "$MODE" == "venv" ]]; then
  echo "[*] Using virtualenv .venv"
  # shellcheck disable=SC1091
  if [[ -f .venv/bin/activate ]]; then source .venv/bin/activate; else source .venv/Scripts/activate; fi
  python -m pip install --no-index --find-links="$WHEELHOUSE" --upgrade pip setuptools wheel 2>/dev/null || true
  python -m pip install --no-index --find-links="$WHEELHOUSE" -r requirements.txt
  TARGET_PY="python"
else
  echo "[*] Installing into user site-packages (no venv): $PY -m pip install --user"
  "$PY" "${PIP_OFFLINE[@]}" --user -r requirements.txt
  TARGET_PY="$PY"
fi

echo ""
echo "[*] Verifying imports..."
"$TARGET_PY" - <<'PY'
import httpx, httpx_socks, openpyxl
import migration.cli, migration.mapping_engine, migration.bssf_migrator
print("  deps + migration package import OK")
PY

echo ""
echo "[OK] Install complete (mode: $MODE)."
if [[ "$MODE" == "venv" ]]; then
  echo "     Activate venv:  source .venv/bin/activate"
else
  echo "     No venv (user install). Just run with your system python ($PY)."
fi
echo "     Edit configs:"
echo "       config/config.json                      (CBEV env/auth/tls)"
echo "       migration/config/migration_config.json  (AIR UCIP endpoint/creds)"
echo "     Run:            ./run.sh --help    (auto-detects venv or system python)"
