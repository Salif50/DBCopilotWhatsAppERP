#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  echo "Fichier .env absent. Lancez: cp .env.example .env" >&2
  exit 1
fi

if ! docker compose config | grep -q 'N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"'; then
  echo "N8N_BLOCK_ENV_ACCESS_IN_NODE=false est absent de la configuration Compose." >&2
  exit 1
fi

echo "Recréation de n8n pour recharger .env..."
docker compose up -d --force-recreate n8n

value="$(docker compose exec -T n8n printenv N8N_BLOCK_ENV_ACCESS_IN_NODE | tr -d '\r')"
if [[ "$value" != "false" ]]; then
  echo "Échec: le conteneur n8n ne voit pas N8N_BLOCK_ENV_ACCESS_IN_NODE=false." >&2
  exit 1
fi

docker compose exec -T n8n sh -c '
  test -n "$PLUTO_ERROR_ADMIN_PHONE" || { echo "PLUTO_ERROR_ADMIN_PHONE manquant" >&2; exit 1; }
  test -n "$PLUTO_GOWA_SESSION_ID" || { echo "PLUTO_GOWA_SESSION_ID manquant" >&2; exit 1; }
'

echo "Configuration n8n rechargée. Réexécutez maintenant le nœud en erreur."
