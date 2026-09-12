# Workflows n8n

## Version officielle

- `PLUTO_DB_Copilot_v7_COMPETITION.json` : agent principal ;
- `PLUTO_DB_Copilot_v7_ERROR_SUPERVISOR.json` : notification privée des erreurs.

Importer les deux fichiers dans n8n et réaffecter les credentials. Les deux
nœuds PostgreSQL contenant `AUDIT ROLE` ou `WRITE AUDIT ONLY` doivent utiliser
la credential `db_copilot_audit`. Tous les autres nœuds PostgreSQL utilisent
`db_copilot_ro`.

La documentation des versions antérieures est conservée dans `docs/archive/`.
Un seul workflow portant le webhook `gowa-db-copilot` doit être actif.
