# Tests PLUTO DB Copilot v6.2

## Parcours utilisateur

| Test | Entrée | Résultat attendu |
|---|---|---|
| Accusé | `Quel est le chiffre d'affaires ?` | Accusé immédiat puis réponse chiffrée |
| Zéro résultat | Question portant sur une période vide | Message clair sans donnée inventée |
| Format | Envoyer une image | Instruction d'utiliser texte ou vocal |
| Vocal invalide | Vocal bruité | Message audio explicite et aucune action |
| SQL invalide | Question poussant vers une table interdite | Refus ou demande de reformulation |
| Graphique | Demander une courbe | Texte puis image, ou texte puis lien de secours |

## Approbation

1. Envoyer `/demo-alerte` depuis le numéro manager.
2. Vérifier la mention `DÉMONSTRATION CONTRÔLÉE`.
3. Répondre `peut-être` : PLUTO doit demander `OUI` ou `NON` sans agir.
4. Répondre `NON` : aucune action externe ne doit partir.
5. Relancer, puis répondre `OUI`.
6. Vérifier la réception sur `PLUTO_DEMO_ACTION_PHONE`.
7. Vérifier que la confirmation contient une référence `PLT-`.
8. Provoquer un échec du numéro de destination : PLUTO doit dire
   `Action non exécutée`, jamais `Fait`.

## Supervision technique

1. Importer et enregistrer le workflow Error Supervisor.
2. Le sélectionner comme `Error workflow` du workflow principal.
3. Vérifier `PLUTO_ERROR_ADMIN_PHONE` et `PLUTO_GOWA_SESSION_ID`.
4. Provoquer une erreur depuis une exécution automatique de test.
5. Vérifier sur WhatsApp : workflow, exécution, dernier nœud, erreur, trace et URL.
6. Répéter immédiatement la même erreur : aucune seconde alerte pendant cinq minutes.

Le Error Trigger ne fonctionne pas lors d'une exécution manuelle lancée depuis
l'éditeur n8n. Utiliser un webhook, un cron ou un autre déclencheur automatique.
