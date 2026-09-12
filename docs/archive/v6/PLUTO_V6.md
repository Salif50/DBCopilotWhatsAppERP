# PLUTO DB Copilot v6

> Mise à jour v6.2 : pour le superviseur d’erreurs, le préflight PostgreSQL et la démonstration contrôlée, consulter `docs/PLUTO_RESILIENCE.md`.

## Résultat

PLUTO v6 transforme le DB Copilot réactif en agent opérationnel. Il conserve
le chemin rapide qui répond aux questions métier, mais ajoute une enquête
autonome capable de tester plusieurs hypothèses, de consulter Exa, de produire
un rapport de décision et de préparer une action soumise à approbation.

Le workflow importable est :

```text
workflows/PLUTO_DB_Copilot_v6_AUTONOMOUS.json
```

La v5 reste intacte et peut être réactivée immédiatement en cas de besoin.

## Capacités

- texte et notes vocales WhatsApp avec GOWA ;
- questions SQL rapides avec `gpt-5.6-terra` ;
- sorties structurées validées par JSON Schema ;
- enquêtes complexes avec `gpt-6-astra` ;
- génération de deux à quatre hypothèses et requêtes complémentaires ;
- validation SQL locale avant toute exécution ;
- PostgreSQL strictement en lecture seule ;
- contexte externe récent avec Exa ;
- sources Web visibles dans le rapport ;
- distinction entre faits, hypothèses et recommandations ;
- simulation et recommandations classées ;
- code d'approbation lié au chat et expirant après 30 minutes ;
- webhook externe appelé uniquement après approbation ;
- surveillance automatique toutes les 30 minutes ;
- déduplication des alertes pendant six heures ;
- graphique QuickChart envoyé sur WhatsApp.

## Architecture

```text
WhatsApp texte ou voix
        |
        v
Router intentions PLUTO
        |
        +-- question rapide --> SQL Guard --> PostgreSQL --> synthèse
        |
        +-- enquête --> plan Astra --> SQL Guard --> 2 à 4 requêtes
        |                                  |
        |                                  v
        |                         preuves PostgreSQL
        |                                  |
        |                                  v
        |                         Exa puis rapport Astra
        |                                  |
        |                                  v
        |                        recommandation à approuver
        |
        +-- APPROUVER CODE --> validation chat et délai --> webhook action

Schedule 30 minutes --> snapshot SQL fixe --> anomalie --> même enquête
```

## Installation

1. Copier les nouvelles variables de `.env.example` dans `.env`.
2. Renseigner au minimum `EXA_API_KEY` pour la recherche externe.
3. Pour les alertes autonomes, renseigner `PLUTO_MANAGER_CHAT_ID` et
   `PLUTO_GOWA_SESSION_ID`.
4. Pour une vraie action, renseigner `PLUTO_ACTION_WEBHOOK_URL` avec une URL
   HTTPS contrôlée. Sans cette variable, l'approbation fonctionne en mode
   démonstration sans effet externe.
5. Redémarrer n8n après modification de l'environnement :

```bash
docker compose up -d --force-recreate n8n
```

6. Importer `workflows/PLUTO_DB_Copilot_v6_AUTONOMOUS.json` dans n8n.
7. Sélectionner la credential OpenAI Bearer sur tous les nœuds OpenAI.
8. Sélectionner la credential PostgreSQL `db_copilot_ro` sur les trois nœuds :
   - `PostgreSQL - ventes READ ONLY` ;
   - `PostgreSQL Investigation READ ONLY` ;
   - `PostgreSQL Snapshot surveillance`.
9. Sélectionner la credential GOWA Basic Auth sur tous les nœuds d'envoi.
10. Tester manuellement, puis activer uniquement la v6. Ne pas laisser la v5
    et la v6 écouter le même webhook simultanément.

## Variables

| Variable | Requise | Usage |
| --- | --- | --- |
| `EXA_API_KEY` | Non | Active l'enrichissement Web. Sans clé, l'enquête continue avec les données internes. |
| `PLUTO_MANAGER_CHAT_ID` | Pour les alertes | Conversation qui reçoit les incidents détectés automatiquement. |
| `PLUTO_GOWA_SESSION_ID` | Pour les alertes | Session GOWA utilisée pour envoyer le message autonome. |
| `PLUTO_ACTION_WEBHOOK_URL` | Pour une vraie action | Destination appelée après validation humaine. |
| `PLUTO_SALES_DROP_THRESHOLD` | Non | Seuil de baisse, `0.20` par défaut. |

## Commandes WhatsApp

```text
/aide
```

Affiche les modes disponibles.

```text
/briefing
```

Lance une enquête globale sur les ventes, encaissements, risques et stocks.

```text
/enquete pourquoi les ventes baissent ce mois-ci
```

Lance le plan multi-requêtes, Exa et la synthèse de décision.

```text
APPROUVER 8CARACT
```

Autorise uniquement l'action attachée à ce code, pour la même conversation et
pendant 30 minutes. Un code expiré, réutilisé ou provenant d'un autre chat est
refusé.

## Scénario de démonstration recommandé

1. Poser une question rapide :

   ```text
   Quel est notre chiffre d'affaires aujourd'hui ?
   ```

2. Envoyer une note vocale :

   ```text
   Fais-moi un graphique du chiffre d'affaires par ville.
   ```

3. Déclencher le mode agent :

   ```text
   /enquete pourquoi les ventes baissent et quels produits risquent une rupture ?
   ```

4. Montrer en direct que PLUTO :
   - crée plusieurs hypothèses ;
   - exécute plusieurs requêtes validées ;
   - consulte Exa ;
   - affiche les sources ;
   - attribue un niveau de confiance ;
   - propose une action avec un code temporaire.

5. Envoyer `APPROUVER CODE` et montrer que l'action n'est exécutée qu'après
   vérification du chat et de l'expiration.

6. Terminer avec le déclencheur programmé et expliquer que le manager n'a plus
   besoin de poser la première question : PLUTO découvre lui-même les incidents.

## Contrat du webhook d'action

Après approbation, PLUTO envoie :

```json
{
  "token": "CODE",
  "approvedBy": "chat_id",
  "action": {
    "title": "Action proposée",
    "rationale": "Motif",
    "payload": {
      "type": "create_task",
      "description": "Description de la tâche",
      "priority": "high"
    }
  }
}
```

Le récepteur doit vérifier le header `X-PLUTO-Approval`, journaliser l'action
et retourner un code HTTP 2xx. Pour la compétition, ce webhook peut créer une
tâche Trello, Asana, ClickUp ou un ticket interne.

## Sécurité

- Le compte PostgreSQL de l'agent reste `db_copilot_ro`.
- Les requêtes générées sont contrôlées localement avant exécution.
- Le planificateur ne peut pas autoriser lui-même son SQL.
- Les sources Exa ne remplacent jamais les preuves de la base.
- Une corrélation ne doit pas être présentée comme une causalité.
- Une action externe exige une confirmation humaine explicite.
- Le token est lié au chat, expire et ne peut être utilisé qu'une fois.
- Aucune clé API n'est écrite dans le JSON du workflow.

Pour la production, remplacer le stockage statique n8n des approbations par
Redis ou une table dédiée, ajouter une allowlist de numéros WhatsApp, parser le
SQL avec un AST et signer les appels du webhook d'action.

## Limites actuelles

- Les résultats des enquêtes dépendent de la richesse des données ERP.
- L'agent n'invente pas de causalité lorsque la base ne contient qu'une
  corrélation.
- Les approbations utilisent le stockage statique du workflow, adapté au
  prototype mais pas à un cluster n8n multi-instance.
- La surveillance couvre actuellement la baisse du chiffre d'affaires et les
  stocks critiques. D'autres détecteurs peuvent être ajoutés sans modifier le
  pipeline d'enquête.

## Validation avant présentation

- Exécuter les cas de `examples/PLUTO_V6_TESTS.md`.
- Vérifier que chaque nœud PostgreSQL utilise le compte en lecture seule.
- Tester Exa activé puis désactivé.
- Tester un code faux, expiré et provenant d'un autre chat.
- Tester l'indisponibilité du webhook d'action.
- Répéter la démonstration avec le réseau coupé pour disposer d'un plan de
  secours basé uniquement sur PostgreSQL.
