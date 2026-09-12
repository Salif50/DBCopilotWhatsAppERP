# Troubleshooting

## `Access to env vars denied` dans un Code node

PLUTO utilise `$env` pour lire les numéros administrateur, la session GOWA, le
seuil de confiance et le token du service interne. Pour l'installation Docker,
`docker-compose.yml` doit contenir :

```yaml
N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"
```

Après toute modification de `.env` ou de Compose, **recréer** le conteneur :

```bash
docker compose up -d --force-recreate n8n
```

`docker compose restart n8n` ne recharge pas les variables. Vérifier sans
afficher les secrets :

```bash
docker compose exec -T n8n printenv N8N_BLOCK_ENV_ACCESS_IN_NODE
docker compose exec -T n8n sh -c 'test -n "$PLUTO_ERROR_ADMIN_PHONE" && echo ADMIN_OK || echo ADMIN_MANQUANT'
docker compose exec -T n8n sh -c 'test -n "$PLUTO_GOWA_SESSION_ID" && echo SESSION_OK || echo SESSION_MANQUANTE'
```

Le premier résultat doit être `false`. Si n8n utilise des workers ou task
runners externes, leur déploiement doit être recréé avec la même configuration.
Sur une instance hébergée où `$env` est volontairement interdit, configurer ces
valeurs par le mécanisme de variables/secrets fourni par l'hébergeur et adapter
les références du workflow.

- `Connection refused ::1:5432`: use `postgres`, not localhost.
- no output after normalization: `chat_presence` is ignored; wait for `event=message`.
- audio format error: binary should be `voice.ogg`, `audio/ogg`.
- bad business transcription: PLUTO uses a dedicated vocabulary-correction step.
- wrong SQL status: use canonical values such as `PAYÉ`.
- JSON mode error: synthesis prompt explicitly requests JSON.
- image format error: final branch uses JPG / `image/jpeg`.
