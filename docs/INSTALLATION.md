# Installer PLUTO DB Copilot v7 avec Docker

Ce guide permet d'installer une nouvelle instance sans dépendre de la machine de
l'équipe. Il couvre Docker, PostgreSQL, Redis, le service AST, n8n et GOWA.

## 1. Prérequis

- Docker Desktop 4+ ou Docker Engine avec `docker compose` v2 ;
- Git ;
- 4 Go de RAM disponibles au minimum ;
- ports `3001` et `5678` libres ; `6333` et `6334` seulement avec Qdrant ;
- clé OpenAI ;
- clé Exa facultative ;
- compte WhatsApp réservé au test.

Vérifier :

```bash
docker --version
docker compose version
git --version
```

## 2. Récupération

```bash
git clone https://github.com/Salif50/DBCopilotWhatsAppERP.git
cd DBCopilotWhatsAppERP
cp .env.example .env
```

Pour un clone SSH :

```bash
git clone git@github.com:Salif50/DBCopilotWhatsAppERP.git
```

## 3. Configuration de `.env`

Remplacer toutes les valeurs `CHANGE_ME`. Générer trois secrets différents :

```bash
openssl rand -hex 32
openssl rand -hex 32
openssl rand -hex 32
```

Variables indispensables :

| Variable | Usage |
|---|---|
| `POSTGRES_PASSWORD` | administration PostgreSQL locale |
| `N8N_ENCRYPTION_KEY` | chiffrement des credentials n8n |
| `GOWA_BASIC_AUTH` | authentification de la passerelle WhatsApp |
| `PLUTO_CONTROL_TOKEN` | appels internes n8n vers le validateur AST/mémoire |
| `DB_COPILOT_DB_PASSWORD` | rôle ERP strictement read-only |
| `DB_COPILOT_AUDIT_PASSWORD` | rôle limité au journal d'action |
| `PLUTO_MANAGER_CHAT_ID` | chat autorisé pour démo, alertes et audit |
| `PLUTO_GOWA_SESSION_ID` | session utilisée pour les envois proactifs |
| `PLUTO_ERROR_ADMIN_PHONE` | réception privée des erreurs techniques |
| `PLUTO_DEMO_ACTION_PHONE` | numéro contrôlé recevant l'action de démonstration |

`PLUTO_MANAGER_CHAT_ID`, `PLUTO_ERROR_ADMIN_PHONE` et
`PLUTO_DEMO_ACTION_PHONE` doivent être des numéros de l'équipe pendant les tests.

## 4. Installation automatisée

```bash
chmod +x scripts/bootstrap-docker.sh
./scripts/bootstrap-docker.sh --demo
```

L'option `--demo` charge le jeu enrichi et prépare les ruptures contrôlées de la
vidéo. Sans elle, seuls le schéma et le petit jeu initial sont chargés :

```bash
./scripts/bootstrap-docker.sh
```

Le script :

1. construit et démarre les services ;
2. attend PostgreSQL ;
3. applique le schéma et les données ;
4. crée `db_copilot_ro` et `db_copilot_audit` ;
5. injecte les mots de passe depuis `.env` ;
6. vérifie la lecture seule, l'audit, Redis et le service AST.

Le script peut être relancé. Le scénario de démo remet le stock final au niveau
attendu, mais il vaut mieux restaurer un volume propre avant l'enregistrement
définitif afin de garder un historique parfaitement lisible.

## 5. Installation SQL manuelle

Si vous ne souhaitez pas utiliser le script :

```bash
docker compose up -d --build
docker compose exec -T postgres psql -U n8n -d n8n < database/01-schema.sql
docker compose exec -T postgres psql -U n8n -d n8n < database/02-seed-demo.sql
docker compose exec -T postgres psql -U n8n -d n8n < database/05-hackathon-demo-data.sql
docker compose exec -T postgres psql -U n8n -d n8n < database/06-demo-scenario.sql
docker compose exec -T postgres psql -U n8n -d n8n < database/03-readonly-user.sql
docker compose exec -T postgres psql -U n8n -d n8n < database/07-pluto-action-audit.sql
```

Puis définir les mots de passe des deux rôles depuis une session administrateur :

```sql
ALTER ROLE db_copilot_ro PASSWORD 'SECRET_READ_ONLY';
ALTER ROLE db_copilot_audit PASSWORD 'SECRET_AUDIT';
```

## 6. Configuration n8n

Ouvrir <http://localhost:5678> et créer le compte propriétaire.

Importer :

- `workflows/PLUTO_DB_Copilot_v7_COMPETITION.json` ;
- `workflows/PLUTO_DB_Copilot_v7_ERROR_SUPERVISOR.json`.

### Credentials

#### PostgreSQL Read Only

```text
Host: postgres
Port: 5432
Database: valeur POSTGRES_DB
User: db_copilot_ro
Password: valeur DB_COPILOT_DB_PASSWORD
SSL: désactivé en local
```

L'affecter à tous les nœuds métier PostgreSQL.

#### PostgreSQL Audit Only

```text
Host: postgres
Port: 5432
Database: valeur POSTGRES_DB
User: db_copilot_audit
Password: valeur DB_COPILOT_AUDIT_PASSWORD
SSL: désactivé en local
```

L'affecter uniquement aux deux nœuds portant les noms `AUDIT ROLE` et
`WRITE AUDIT ONLY`.

#### OpenAI

Créer un credential HTTP Bearer Auth avec la clé OpenAI et le sélectionner sur
tous les appels OpenAI. La clé ne doit pas être placée dans le workflow JSON.

#### GOWA

Créer un credential HTTP Basic Auth correspondant à `GOWA_BASIC_AUTH` et le
sélectionner sur tous les nœuds GOWA.

#### Exa

Facultatif : créer un Header Auth `x-api-key`. Sans Exa, PLUTO continue et
indique clairement que le contexte externe est indisponible.

### Supervision

Dans les paramètres du workflow principal, choisir
`PLUTO DB Copilot v7 - Error Supervisor WhatsApp` comme workflow d'erreur. Puis
activer les deux workflows.

## 7. Connexion WhatsApp

1. Ouvrir <http://localhost:3001>.
2. Associer le compte WhatsApp de test à la session GOWA.
3. Configurer l'URL de webhook active :
   `http://n8n:5678/webhook/gowa-db-copilot`.
4. Copier l'identifiant de session dans `PLUTO_GOWA_SESSION_ID`.
5. Recréer n8n après changement de `.env`. Un simple `restart` conserve
   l'ancien environnement du conteneur :

```bash
docker compose up -d --force-recreate n8n
```

La commande suivante automatise la recréation et vérifie la configuration sans
afficher les valeurs sensibles :

```bash
./scripts/reload-n8n-environment.sh
```

Ne pas employer l'URL `localhost` depuis un conteneur. Les noms internes sont
`postgres`, `gowa`, `redis`, `pluto-control` et `n8n`.

## 8. Vérification

```bash
docker compose ps
docker compose logs --tail=100 postgres redis pluto-control n8n gowa
curl -fsS http://localhost:5678/healthz
```

Vérifier le contrôle AST :

```bash
docker compose exec -T pluto-control python - <<'PY'
import json, urllib.request
print(json.load(urllib.request.urlopen('http://localhost:8080/health')))
PY
```

Dans WhatsApp, exécuter dans cet ordre :

1. `Quel est le chiffre d'affaires payé ce mois-ci ?`
2. `Et pour le mois dernier ?`
3. `Fais-en un graphique.`
4. `/demo-alerte`
5. `NON` lors du premier essai de sécurité.

Effectuer ensuite la démo complète avec
[`../examples/QUESTIONS_LIVE_JURY.md`](../examples/QUESTIONS_LIVE_JURY.md).

## 9. Exposition publique facultative

Pour ngrok :

```bash
docker compose --profile tunnel up -d ngrok
docker compose logs -f ngrok
```

Mettre ensuite `N8N_PROTOCOL=https`, `N8N_HOST` et `WEBHOOK_URL` à jour. Pour
une vraie production, utiliser un domaine stable, TLS, une politique de
sauvegarde et une rotation des secrets.

## 10. Arrêt et sauvegarde

Arrêt conservant les données :

```bash
docker compose stop
```

Redémarrage :

```bash
docker compose up -d
```

Ne pas lancer `docker compose down -v` sauf si vous voulez réellement supprimer
les volumes PostgreSQL, Redis, n8n et GOWA.

## 11. Dépannage rapide

| Problème | Vérification |
|---|---|
| n8n ne démarre pas | `docker compose logs n8n postgres pluto-control` |
| mémoire absente | santé Redis et `PLUTO_CONTROL_TOKEN` identique |
| SQL toujours refusé | credential read-only, service AST et préflight |
| WhatsApp ne répond pas | session GOWA, Basic Auth, webhook actif |
| alerte proactive absente | manager/session renseignés et confiance au-dessus du seuil |
| `/audit` échoue | credential audit sur les deux nœuds dédiés |
| action non envoyée | destination de démo, session et logs GOWA |

Voir aussi [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
