#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

bash -n scripts/bootstrap-docker.sh
docker compose --env-file .env.example config --quiet
node scripts/validate-workflows.mjs \
  workflows/PLUTO_DB_Copilot_v7_COMPETITION.json \
  workflows/PLUTO_DB_Copilot_v7_ERROR_SUPERVISOR.json
python3 -m py_compile services/pluto-control-plane/app.py

if python3 -c 'import pytest, fastapi, redis, sqlglot' >/dev/null 2>&1; then
  PYTHONPATH=services/pluto-control-plane \
    python3 -m pytest -q services/pluto-control-plane/test_app.py
else
  echo "Tests Python non exécutés localement : installez pytest et requirements.txt."
fi

echo "Dépôt PLUTO validé."
