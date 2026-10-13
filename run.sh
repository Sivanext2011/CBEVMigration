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
if [[ -f .venv/bin/activate ]]; then source .venv/bin/activate
elif [[ -f .venv/Scripts/activate ]]; then source .venv/Scripts/activate; fi
exec python -m migration.cli "$@"
