# Sécurité

La sécurité repose sur plusieurs couches.

1. Compte PostgreSQL dédié `db_copilot_ro`.
2. `default_transaction_read_only=on`.
3. Droits SELECT uniquement sur les tables métier.
4. Prompt Text-to-SQL limité à SELECT.
5. Validateur n8n bloquant commandes destructrices, commentaires SQL, CTE, catalogues système et tables non autorisées.
6. Requête enveloppée avec une limite maximale.
7. `statement_timeout` PostgreSQL.
8. Secrets uniquement dans credentials n8n / `.env`, jamais dans Git.
9. Messages `is_from_me` et groupes ignorés.
10. Les informations client sensibles ne doivent pas être retournées si la question ne les demande pas.

Pour une production réelle, ajouter authentification/allowlist des numéros managers, journal d'audit, rate limiting, politique de rétention et séparation de la base n8n de la base métier.
