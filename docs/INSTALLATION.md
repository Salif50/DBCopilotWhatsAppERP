# Installation

```bash
cp .env.example .env
docker compose up -d
```

Connexion PostgreSQL administrateur :

```bash
docker exec -it cjp-postgres psql -U n8n -d n8n
```

Puis exécuter dans l'ordre :
1. `database/01-schema.sql`
2. `database/02-seed-demo.sql`
3. `database/03-readonly-user.sql`
4. `database/04-test-queries.sql`

Dans n8n :
- importer le workflow JSON ;
- sélectionner les credentials OpenAI ;
- créer la credential PostgreSQL avec host `postgres`, port `5432`, database `n8n`, user `db_copilot_ro` ;
- sélectionner la credential Basic Auth GOWA ;
- vérifier le `X-Device-Id` dynamique ;
- activer le workflow.

Depuis n8n, ne pas utiliser `localhost` pour PostgreSQL ou GOWA : utiliser les noms Docker `postgres` et `gowa`.
