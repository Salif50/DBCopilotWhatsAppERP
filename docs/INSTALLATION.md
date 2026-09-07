# Installation

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Then execute database scripts in order:
1. `01-schema.sql`
2. `02-seed-demo.sql`
3. `03-readonly-user.sql`
4. `04-test-queries.sql`

n8n PostgreSQL credential:
- Host: `postgres`
- Port: `5432`
- Database: `n8n`
- User: `db_copilot_ro`
- SSL: disabled for the local demo

Import the final workflow and re-select OpenAI, PostgreSQL and GOWA credentials.
