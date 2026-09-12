# PLUTO DB Copilot v6.2

## Objet

Cette version renforce la fiabilité de la démonstration et la supervision du
workflow. Elle garantit une réponse compréhensible sur les chemins utilisateur,
vérifie les requêtes SQL avec PostgreSQL avant leur exécution et signale les
erreurs automatiques à un administrateur WhatsApp.

## Fichiers à importer

1. `workflows/PLUTO_DB_Copilot_v6_ERROR_SUPERVISOR.json`
2. `workflows/PLUTO_DB_Copilot_v6_AUTONOMOUS.json`

Le premier est un workflow d'erreur séparé. Le second est l'agent principal.

## Configuration obligatoire

Ajouter les valeurs suivantes dans `.env`, puis redémarrer n8n :

```dotenv
PLUTO_MANAGER_CHAT_ID=224XXXXXXXXX
PLUTO_ERROR_ADMIN_PHONE=224XXXXXXXXX
PLUTO_GOWA_SESSION_ID=identifiant-session-gowa
PLUTO_DEMO_ACTION_PHONE=224XXXXXXXXX
PLUTO_SALES_DROP_THRESHOLD=0.20
```

- `PLUTO_MANAGER_CHAT_ID` reçoit les alertes métier et peut lancer la démo.
- `PLUTO_ERROR_ADMIN_PHONE` reçoit les diagnostics techniques.
- `PLUTO_GOWA_SESSION_ID` identifie la session WhatsApp utilisée pour les envois.
- `PLUTO_DEMO_ACTION_PHONE` reçoit l'action simulée après `OUI`. Utiliser un
  numéro contrôlé par l'équipe, jamais celui d'un vrai fournisseur.
- `PLUTO_SALES_DROP_THRESHOLD=0.20` représente une baisse de 20 pour cent.

## Activer le superviseur d'erreurs

1. Importer `PLUTO_DB_Copilot_v6_ERROR_SUPERVISOR.json`.
2. Sélectionner le credential Basic Auth GOWA dans son nœud d'envoi.
3. Enregistrer ce workflow. Il n'a pas besoin d'être activé.
4. Ouvrir les paramètres du workflow principal.
5. Dans `Error workflow`, sélectionner
   `PLUTO DB Copilot v6 - Error Supervisor WhatsApp`.
6. Enregistrer, puis activer le workflow principal.

Le `Error Trigger` reçoit le nom du workflow, l'exécution, le dernier nœud,
le message d'erreur, la trace et l'URL de diagnostic. Les clés et jetons
reconnaissables sont masqués avant WhatsApp. Une même erreur répétée est
silencée pendant cinq minutes pour éviter une tempête d'alertes.

Les erreurs volontairement gérées par une réponse de secours ne font pas
échouer l'exécution n8n. Le workflow principal les signale donc aussi au numéro
administrateur par une branche dédiée. Cela couvre notamment OpenAI,
PostgreSQL, l'audio, les graphiques, Exa et l'envoi d'une action approuvée.

Important : n8n déclenche un workflow d'erreur uniquement pour une exécution
automatique, pas pendant un test manuel dans l'éditeur.

## Réponses de secours ajoutées

- Accusé immédiat avant toute analyse texte ou vocale.
- Message explicite pour image, document, vidéo ou sticker non supporté.
- Réponse de secours pour téléchargement audio, transcription et correction.
- Réponse sans invention lorsque la recherche Exa est indisponible.
- Résultat texte conservé et lien envoyé si le graphique échoue.
- Échec d'action annoncé comme non exécuté, sans faux message de réussite.
- Confirmation `OUI` ou `NON` obligatoire et valable 30 minutes.
- Contexte de l'approbation restauré après l'appel HTTP avant confirmation.

## Sécurité SQL renforcée

La validation comporte maintenant trois couches :

1. liste déterministe des opérations et tables autorisées ;
2. `EXPLAIN FORMAT JSON` pour faire analyser le SQL par le vrai parseur
   PostgreSQL avant exécution ;
3. exécution avec la credential PostgreSQL strictement en lecture seule.

Le préflight PostgreSQL est appliqué aux questions utilisateur et aux requêtes
générées pendant l'enquête proactive.

## Démonstration devant le jury

Depuis le numéro configuré dans `PLUTO_MANAGER_CHAT_ID`, envoyer :

```text
/demo-alerte
```

PLUTO exécute alors la chaîne complète : lecture des chiffres réels de la base,
investigation, recherche externe, synthèse, proposition d'action et demande
d'approbation. Le message précise qu'il s'agit d'une simulation contrôlée si
les données ne contiennent pas une vraie anomalie.

Répondre ensuite :

```text
OUI
```

L'action est envoyée uniquement vers `PLUTO_DEMO_ACTION_PHONE`. PLUTO n'affiche
la confirmation de réussite qu'après le succès du connecteur WhatsApp. En cas
d'échec, il affirme clairement que rien n'a été envoyé et permet une nouvelle
tentative tant que l'autorisation reste valide.

## Tests indispensables avant présentation

1. Question texte valide et réponse finale.
2. Question sans résultat et message `aucune donnée trouvée`.
3. Note vocale claire puis note vocale volontairement inutilisable.
4. Image ou document reçu et réponse de format non supporté.
5. Demande SQL mal formée rejetée par le préflight.
6. Graphique valide puis panne QuickChart simulée.
7. `/demo-alerte`, réponse autre que `OUI/NON`, puis `NON`.
8. `/demo-alerte`, puis `OUI`, avec réception réelle sur le numéro de test.
9. `OUI` après expiration de 30 minutes.
10. Échec automatique contrôlé avec réception du diagnostic administrateur.

Le workflow principal reste désactivé dans le JSON exporté. Ne l'activer
qu'après avoir sélectionné les credentials OpenAI, Exa, PostgreSQL et GOWA.
