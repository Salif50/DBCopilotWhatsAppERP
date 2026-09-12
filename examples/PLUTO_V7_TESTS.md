# Matrice de tests PLUTO v7

Exécuter ces tests sur une copie de démonstration. Capturer l'exécution n8n et
le WhatsApp reçu. Une répétition complète doit réussir trois fois avant jury.

| ID | Test | Résultat attendu |
|---|---|---|
| T01 | Question CA du mois | Accusé, réponse chiffrée, aucune erreur silencieuse |
| T02 | « Et pour le mois dernier ? » | Contexte précédent utilisé |
| T03 | « Fais-en un graphique » | Graphique ou secours texte explicite |
| T04 | Période sans résultat | « Aucune donnée pour cette période » |
| T05 | Question hors ERP | Refus clair, sans SQL exécuté |
| T06 | Image ou document | Format non supporté clairement annoncé |
| T07 | Note vocale correcte | Transcription puis réponse métier |
| T08 | Note vocale ambiguë | Demande de reformulation, sans requête inventée |
| T09 | SQL initial invalide | Un seul essai de correction, puis validation complète |
| T10 | SQL d'écriture ou injection | Refus avant PostgreSQL métier |
| T11 | Service AST arrêté | Pas d'exécution SQL ; message de secours + alerte admin |
| T12 | Redis arrêté | Question complète encore traitée ; suivi dégradé signalé à l'admin |
| T13 | Cron sans anomalie | Fin normale, aucun WhatsApp |
| T14 | Confiance sous seuil | Fin silencieuse, aucune approbation créée |
| T15 | `/demo-alerte` hors manager | Refus, aucune action en attente |
| T16 | `/demo-alerte` manager | Alerte contrôlée avec confiance et référence |
| T17 | Réponse autre que OUI/NON | Clarification, aucune action |
| T18 | OUI après 30 minutes | Autorisation expirée, aucune action |
| T19 | OUI depuis un autre chat | Aucune exécution de l'action du manager |
| T20 | NON | Annulation, pending supprimé, aucune action |
| T21 | OUI avec GOWA opérationnel | Message reçu sur numéro test, confirmation, audit |
| T22 | OUI avec GOWA en panne | « Action non exécutée », aucune fausse confirmation |
| T23 | `/audit` manager | Cinq dernières actions maximum |
| T24 | `/audit` hors manager | Accès refusé |
| T25 | Échec d'écriture audit | Action distinguée de l'audit incomplet + alerte admin |
| T26 | Erreur n8n non gérée | Superviseur envoie workflow, nœud, exécution et détail à l'admin |

## Tests automatisés disponibles

```bash
python3 -m py_compile services/pluto-control-plane/app.py
PYTHONPATH=services/pluto-control-plane pytest -q services/pluto-control-plane/test_app.py
docker compose --env-file .env.example config --quiet
```

Le validateur automatisé couvre : SELECT métier autorisé, écriture, table
système, UNION, sous-requête, fonction système, `SELECT INTO` et authentification.

## Critères go/no-go

- Zéro faux succès d'action.
- Zéro action sans approbation du même chat.
- Zéro requête métier sans AST valide et préflight PostgreSQL.
- T01, T02, T03, T16, T21 et T23 réussissent trois fois consécutives.
- Le numéro administrateur reçoit T11, T22, T25 et T26.
