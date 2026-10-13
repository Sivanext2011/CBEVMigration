#!/usr/bin/env bash
# run.sh — convenience wrapper: activates .venv (if present) and runs the CLI.
# Examples:
#   ./run.sh --help
#   ./run.sh migrate 886970007050 --dry-run
#   ./run.sh batch msisdns.txt
#   ./run.sh report
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
if [[ -f .venv/bin/activate ]]; then
  source .venv/bin/activate
  exec python -m migration.cli "$@"
elif [[ -f .venv/Scripts/activate ]]; then
  source .venv/Scripts/activate
  exec python -m migration.cli "$@"
fi
# No venv (user/system install): find a python 3.11+
for c in python3.12 python3.11 python3 python; do
  if command -v "$c" >/dev/null 2>&1; then exec "$c" -m migration.cli "$@"; fi
done
echo "No python found" >&2; exit 1
