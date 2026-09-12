# PLUTO DB Copilot v7 — Competition Agent

## Positionnement

> **PLUTO est un agent métier qui vit dans WhatsApp, surveille l'entreprise,
> explique les anomalies et agit seulement après une approbation humaine.**

Le Text-to-SQL n'est pas le produit : c'est une capacité interne. L'expérience
complète est : comprendre, vérifier, mémoriser, surveiller, enquêter, proposer,
demander l'autorisation, agir et prouver l'action.

## Ce que la v7 apporte

| Risque ou critère | Réponse de PLUTO v7 |
|---|---|
| Requête SQL invalide | Autocorrection, une seule fois, puis nouveau passage dans toutes les barrières |
| Injection ou requête dangereuse | Contrôle lexical, AST SQLGlot, `EXPLAIN` PostgreSQL et rôle métier read-only |
| Question de suivi | Mémoire Redis : « et pour le mois dernier ? », « fais-en un graphique » |
| Résultat vide | Réponse explicite, sans inventer de données |
| Service secondaire indisponible | Réponse de secours et diagnostic privé à l'administrateur |
| Alerte peu fiable | Silence volontaire sous `PLUTO_PROACTIVE_CONFIDENCE_MIN` |
| Action externe | OUI/NON, autorisation liée au chat, expiration à 30 minutes |
| Preuve d'exécution | Journal PostgreSQL, référence d'approbation et commande `/audit` |
| Panne non gérée n8n | Workflow Error Trigger séparé vers le numéro administrateur |

## Architecture

```text
WhatsApp / GOWA
      │
      ▼
n8n — normalisation, accusé immédiat et routage
      ├── Redis via pluto-control : mémoire courte
      ├── OpenAI : Text-to-SQL, correction et synthèse
      ├── pluto-control : validation AST SQLGlot
      ├── PostgreSQL read-only : EXPLAIN puis SELECT
      ├── Exa : contexte externe facultatif et signalé comme tel
      └── PostgreSQL audit-only : preuve des actions approuvées
```

Le service `pluto-control` reste sur le réseau Docker interne. Il exige le
header `X-PLUTO-Token`, ne stocke aucune ligne métier dans Redis et hache
l'identifiant de conversation utilisé comme clé.

## Les quatre barrières SQL

1. Le prompt limite le modèle aux tables et valeurs métier autorisées.
2. Le filtre déterministe refuse écritures, commentaires, instructions multiples,
   schémas système et tables inconnues.
3. SQLGlot parse la requête en AST et refuse toute structure interdite.
4. PostgreSQL exécute `EXPLAIN` avec le rôle read-only avant le vrai `SELECT`.

Une correction automatique ne contourne jamais ces contrôles : elle revient au
début de la chaîne de validation. Un état borné par message interdit une boucle
infinie et limite la réparation à un essai.

## Installation de la v7

### 1. Variables

Copier `.env.example` vers `.env`, puis renseigner au minimum :

- `PLUTO_MANAGER_CHAT_ID` ;
- `PLUTO_GOWA_SESSION_ID` ;
- `PLUTO_ERROR_ADMIN_PHONE` ;
- `PLUTO_DEMO_ACTION_PHONE`, obligatoirement un numéro de l'équipe ;
- `PLUTO_CONTROL_TOKEN`, secret long et aléatoire ;
- `PLUTO_PROACTIVE_CONFIDENCE_MIN=75`.

Ne jamais mettre de clé API ou numéro réel dans les workflows exportés.

### 2. Infrastructure et rôles

```bash
cp .env.example .env
# Remplacer les valeurs CHANGE_ME dans .env, puis :
chmod +x scripts/bootstrap-docker.sh
./scripts/bootstrap-docker.sh --demo
docker compose ps
docker compose exec pluto-control python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read().decode())"
```

Le démarrage de n8n attend que Redis et `pluto-control` soient sains.

### 3. Rôles PostgreSQL

Le bootstrap crée les rôles et injecte leurs mots de passe depuis `.env`. La
procédure manuelle est décrite dans `docs/INSTALLATION.md`.

Dans n8n, conserver la credential `db_copilot_ro` sur tous les nœuds métier.
Créer une seconde credential PostgreSQL `db_copilot_audit` et l'affecter
uniquement à :

- `Lire journal actions (AUDIT ROLE)` ;
- `Journaliser action (WRITE AUDIT ONLY)`.

Ce rôle peut insérer et consulter le journal. Il ne peut ni lire les tables ERP,
ni modifier ou supprimer une entrée d'audit.

### 4. Workflows n8n

Importer et activer :

1. `workflows/PLUTO_DB_Copilot_v7_COMPETITION.json` ;
2. `workflows/PLUTO_DB_Copilot_v7_ERROR_SUPERVISOR.json`.

Réaffecter les credentials OpenAI, GOWA et PostgreSQL après l'import. Dans les
paramètres du workflow principal, sélectionner le superviseur comme workflow
d'erreur si la version de n8n ne le fait pas automatiquement.

## Comportements attendus

### Question normale

PLUTO accuse réception, transforme la question en lecture SQL, vérifie la
requête, répond et mémorise seulement le contexte nécessaire au prochain tour.

### Suivi conversationnel

Après « Quel est le chiffre d'affaires ce mois-ci ? », le manager peut dire
« et pour le mois dernier ? », puis « fais-en un graphique ». La mémoire expire
par défaut après 24 heures.

### Erreur SQL

PLUTO tente une seule réparation. Si elle échoue, l'utilisateur reçoit une
réponse claire et l'administrateur reçoit le détail technique. PLUTO ne promet
jamais une réponse qu'il n'a pas produite.

### Proactivité contrôlée

L'agent calcule un niveau de confiance. Sous le seuil, le workflow se termine
normalement sans WhatsApp et sans créer d'autorisation en attente. Au-dessus,
il expose les preuves, la cause probable, l'impact, l'action et la référence.

### Action

Seul un OUI explicite du même chat, reçu avant expiration, déclenche le connecteur.
La confirmation n'est envoyée qu'après succès réel du connecteur. L'action est
ensuite journalisée. Si le journal échoue, le message distingue clairement
« action exécutée » de « audit incomplet » et alerte l'administrateur.

## Commandes de jury

- `/demo-alerte` : déclenche la séquence proactive reproductible, seulement
  depuis le chat manager, vers le numéro de démonstration contrôlé ;
- `OUI` : exécute l'action proposée ;
- `NON` : annule ;
- `/audit` : affiche les cinq dernières preuves d'action, seulement au manager.

## Sécurité de la démonstration

- Utiliser un numéro WhatsApp appartenant à l'équipe comme destination.
- Présenter `/demo-alerte` comme une simulation contrôlée basée sur les vraies
  données, jamais comme une anomalie réelle.
- Ne pas désactiver le rôle read-only pour résoudre un problème de credential.
- Ne pas baisser le seuil de confiance pour embellir une alerte réelle.

## Test avant jury

Exécuter toute la matrice de `examples/PLUTO_V7_TESTS.md`, puis répéter le
script `examples/PLUTO_V7_DEMO_4_TEMPS.md` trois fois sans modifier le workflow.
Le go/no-go est simple : aucune action ne doit partir sans OUI et chaque OUI
réussi doit apparaître dans `/audit`.

## Références techniques

- SQLGlot, parseur et représentation AST : <https://github.com/tobymao/sqlglot>
- Paramètres de requête du nœud PostgreSQL n8n : <https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/>
- Workflow d'erreur n8n : <https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.errortrigger/>
