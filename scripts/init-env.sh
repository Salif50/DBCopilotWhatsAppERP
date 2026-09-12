#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Création de .env depuis .env.example."
fi

command -v openssl >/dev/null 2>&1 || {
  echo "OpenSSL est requis pour générer les secrets." >&2
  exit 1
}

set_value() {
  local key="$1"
  local value="$2"
  local temp_file
  temp_file="$(mktemp)"
  awk -v wanted="$key" -v replacement="$value" '
    BEGIN { found=0 }
    index($0, wanted "=")==1 { print wanted "=" replacement; found=1; next }
    { print }
    END { if (!found) print wanted "=" replacement }
  ' .env > "$temp_file"
  mv "$temp_file" .env
}

needs_value() {
  local key="$1"
  local current
  current="$(awk -F= -v wanted="$key" '$1==wanted {sub(/^[^=]*=/, ""); print; exit}' .env)"
  [[ -z "$current" || "$current" == *CHANGE_ME* ]]
}

ensure_secret() {
  local key="$1"
  local prefix="${2:-}"
  if needs_value "$key"; then
    set_value "$key" "${prefix}$(openssl rand -hex 32)"
    echo "Secret généré : $key"
  else
    echo "Valeur existante conservée : $key"
  fi
}

N8N_KEY_RECOVERED=false

recover_n8n_key_from_volume() {
  command -v docker >/dev/null 2>&1 || return 0
  local project_name volume_name stored_key current_key
  project_name="${COMPOSE_PROJECT_NAME:-$(basename "$PROJECT_DIR")}"
  volume_name="$(docker volume ls \
    --filter "label=com.docker.compose.project=$project_name" \
    --filter "label=com.docker.compose.volume=n8n_data" \
    --format '{{.Name}}' | head -n 1)"
  [[ -n "$volume_name" ]] || return 0

  stored_key="$(docker run --rm --entrypoint node \
    -v "$volume_name:/data:ro" n8nio/n8n:latest \
    -e "const fs=require('fs');try{const c=JSON.parse(fs.readFileSync('/data/config','utf8'));process.stdout.write(c.encryptionKey||'')}catch(e){}")"
  [[ -n "$stored_key" ]] || return 0
  N8N_KEY_RECOVERED=true

  current_key="$(awk -F= '$1=="N8N_ENCRYPTION_KEY" {sub(/^[^=]*=/, ""); print; exit}' .env)"
  if [[ "$stored_key" != "$current_key" ]]; then
    set_value N8N_ENCRYPTION_KEY "$stored_key"
    echo "Clé n8n existante récupérée depuis le volume persistant."
  else
    echo "Clé n8n existante déjà cohérente."
  fi
}

ensure_secret POSTGRES_PASSWORD
recover_n8n_key_from_volume
if [[ "$N8N_KEY_RECOVERED" != true ]]; then
  ensure_secret N8N_ENCRYPTION_KEY
fi
ensure_secret GOWA_BASIC_AUTH "admin:"
ensure_secret PLUTO_CONTROL_TOKEN
ensure_secret DB_COPILOT_DB_PASSWORD
ensure_secret DB_COPILOT_AUDIT_PASSWORD
ensure_secret WAHA_DASHBOARD_PASSWORD
ensure_secret WAHA_API_KEY

chmod 600 .env
echo "Configuration secrète prête. Les numéros et identifiants existants n'ont pas été modifiés."
