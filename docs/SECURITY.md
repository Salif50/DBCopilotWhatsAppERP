# Sécurité PLUTO DB Copilot v7

## Lecture des données

PLUTO applique une défense en profondeur :

1. schéma et valeurs métier autorisés dans le prompt ;
2. SELECT unique, sans commentaire ni point-virgule ;
3. refus déterministe des opérations d'écriture ;
4. AST SQLGlot avec allowlist des tables, fonctions et relations `JOIN` ;
5. refus des sous-requêtes, CTE et opérations ensemblistes dans cette version ;
6. `EXPLAIN` par PostgreSQL avant exécution ;
7. rôle `db_copilot_ro` avec `default_transaction_read_only=on` ;
8. timeout et limite du nombre de lignes.

Une autocorrection SQL est limitée à un seul essai et repasse par toutes les
barrières.

## Action externe

- aucune action sans OUI explicite ;
- approbation liée au même chat ;
- expiration après trente minutes ;
- destination de démonstration contrôlée par variable d'environnement ;
- confirmation envoyée seulement après succès du connecteur ;
- référence d'approbation conservée dans l'audit.

## Journal d'audit

`db_copilot_audit` possède seulement `INSERT` et `SELECT` sur le journal, plus
l'accès à sa séquence. `UPDATE`, `DELETE` et `TRUNCATE` sont révoqués. Il ne
possède aucun droit sur les tables métier.

## Mémoire

La clé Redis dérive d'un SHA-256 du chat. Le contenu est limité à la question,
au résumé, au SQL généré et à l'intention graphique. Aucune ligne métier n'est
mise en cache. L'expiration est configurable et limitée côté service.

## Secrets

- `.env` est ignoré par Git ;
- les clés OpenAI/GOWA/Exa restent dans les credentials n8n ;
- le service interne exige `X-PLUTO-Token` ;
- aucun secret ni numéro réel ne doit apparaître dans un export de workflow.

## Avant production

Ajouter HTTPS, sauvegardes chiffrées, rotation des secrets, rate limiting,
observabilité centralisée, politique de rétention et revue juridique de l'usage
de WhatsApp. Pour plusieurs entreprises, ajouter isolation par tenant et RLS.
