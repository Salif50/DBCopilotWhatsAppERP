#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

DEMO_MODE=false
case "${1:-}" in
  "") ;;
  --demo) DEMO_MODE=true ;;
  -h|--help)
    echo "Usage: ./scripts/bootstrap-docker.sh [--demo]"
    echo "  --demo  charge aussi les données enrichies et le scénario jury"
    exit 0
    ;;
  *) echo "Option inconnue: $1" >&2; exit 2 ;;
esac

if [[ ! -f .env ]]; then
  echo "Fichier .env absent. Lancez: cp .env.example .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

required=(
  POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB N8N_ENCRYPTION_KEY
  GOWA_BASIC_AUTH PLUTO_CONTROL_TOKEN DB_COPILOT_DB_PASSWORD
  DB_COPILOT_AUDIT_PASSWORD
)

for name in "${required[@]}"; do
  value="${!name:-}"
  if [[ -z "$value" || "$value" == *CHANGE_ME* ]]; then
    echo "Variable obligatoire absente ou non modifiée dans .env: $name" >&2
    exit 1
  fi
done

command -v docker >/dev/null 2>&1 || {
  echo "Docker est requis." >&2
  exit 1
}
docker compose version >/dev/null

echo "[1/5] Construction et démarrage des services PLUTO..."
docker compose up -d --build postgres redis pluto-control n8n gowa

echo "[2/5] Attente de PostgreSQL..."
ready=false
for _ in {1..60}; do
  if docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo "PostgreSQL n'est pas devenu disponible." >&2
  docker compose logs --tail=100 postgres >&2
  exit 1
fi

apply_sql() {
  local file="$1"
  echo "  -> $file"
  docker compose exec -T postgres \
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    < "$file"
}

echo "[3/5] Schéma, données et rôles à privilèges minimaux..."
apply_sql database/01-schema.sql
apply_sql database/02-seed-demo.sql
if [[ "$DEMO_MODE" == true ]]; then
  apply_sql database/05-hackathon-demo-data.sql
  apply_sql database/06-demo-scenario.sql
fi
apply_sql database/03-readonly-user.sql
apply_sql database/07-pluto-action-audit.sql

docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v ro_password="$DB_COPILOT_DB_PASSWORD" \
  -v audit_password="$DB_COPILOT_AUDIT_PASSWORD" <<'SQL'
SELECT format('ALTER ROLE db_copilot_ro PASSWORD %L', :'ro_password') \gexec
SELECT format('ALTER ROLE db_copilot_audit PASSWORD %L', :'audit_password') \gexec
SQL

echo "[4/5] Vérification des protections..."
ro_mode="$(docker compose exec -T -e PGPASSWORD="$DB_COPILOT_DB_PASSWORD" postgres \
  psql -Atq -U db_copilot_ro -d "$POSTGRES_DB" \
  -c 'SHOW default_transaction_read_only' | tr -d '\r')"
if [[ "$ro_mode" != "on" ]]; then
  echo "Le rôle db_copilot_ro n'est pas en lecture seule." >&2
  exit 1
fi

docker compose exec -T -e PGPASSWORD="$DB_COPILOT_AUDIT_PASSWORD" postgres \
  psql -v ON_ERROR_STOP=1 -Atq -U db_copilot_audit -d "$POSTGRES_DB" \
  -c 'SELECT count(*) FROM public.v_pluto_action_audit' >/dev/null

docker compose exec -T pluto-control python - <<'PY'
import json
import urllib.request

health = json.load(urllib.request.urlopen("http://localhost:8080/health"))
assert health["redis"] is True, health
print("  -> pluto-control et Redis: OK")
PY

echo "[5/5] Installation terminée."
docker compose ps
echo
echo "Étapes manuelles restantes:"
echo "  1. Ouvrir http://localhost:5678"
echo "  2. Importer les deux workflows v7"
echo "  3. Affecter les credentials OpenAI, GOWA, PostgreSQL RO et audit"
echo "  4. Connecter WhatsApp dans GOWA sur http://localhost:3001"
echo "  5. Activer les workflows et lancer examples/QUESTIONS_LIVE_JURY.md"
