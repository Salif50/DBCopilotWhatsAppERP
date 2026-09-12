# Démonstration jury PLUTO v7 — 4 temps, 5 minutes

## Message d'ouverture — 20 secondes

> PLUTO n'est pas un chatbot SQL. C'est un agent métier installé dans WhatsApp :
> il répond, mémorise le contexte, surveille l'entreprise, enquête et peut agir.
> Mais le modèle ne possède jamais le droit d'action : il propose, l'humain
> autorise et une règle déterministe exécute puis journalise.

## Temps 1 — Comprendre et garder le contexte

Envoyer :

> Quel est le chiffre d'affaires payé ce mois-ci ?

Puis :

> Et pour le mois dernier ?

Puis :

> Fais-en un graphique.

À montrer au jury : accusé immédiat, vraie réponse issue de PostgreSQL, suivi
naturel sans répéter le sujet, puis graphique. Dire que Redis conserve un
résumé limité pendant 24 h et non les lignes métier.

## Temps 2 — Surveiller et proposer

Envoyer depuis le numéro manager :

> /demo-alerte

À montrer : mention « démonstration contrôlée », chiffres provenant de la base,
cause probable, contexte externe s'il est disponible, impact, confiance, action,
référence d'autorisation et choix OUI/NON.

Phrase jury :

> Le déclencheur de démonstration rend la scène reproductible. En production,
> le même pipeline part du cron et d'un signal réel.

## Temps 3 — Prouver qu'il sait se taire

Avant la démo, conserver `PLUTO_PROACTIVE_CONFIDENCE_MIN=75`. Montrer dans
l'exécution n8n une occurrence terminée dans l'un des nœuds :

- `Fin normale sans anomalie ventes` ;
- `Fin normale sans anomalie stock` ;
- `Fin normale confiance insuffisante` ;
- `Fin normale confiance rupture insuffisante`.

Phrase jury :

> Un agent mature ne cherche pas à monopoliser WhatsApp. Sans anomalie ou sous
> le seuil de confiance, il ne crée ni message ni autorisation en attente.

Ne pas envoyer une question utilisateur en espérant que PLUTO l'ignore : ce
temps montre la discipline de la surveillance proactive, pas un silence face à
un humain.

## Temps 4 — Agir et prouver

Répondre :

> OUI

Vérifier devant le jury :

1. le message arrive réellement sur `PLUTO_DEMO_ACTION_PHONE` ;
2. PLUTO confirme seulement après le succès du connecteur ;
3. la confirmation contient la même référence d'autorisation.

Puis envoyer :

> /audit

Montrer la dernière ligne : action, quatre derniers chiffres, statut, heure et
référence. Ouvrir si utile la credential `db_copilot_audit` pour prouver qu'elle
n'a aucun droit sur les données ERP.

## Conclusion — 20 secondes

> La frontière est volontaire : le LLM comprend et propose ; l'AST et
> PostgreSQL protègent la lecture ; l'humain autorise ; une règle déterministe
> exécute ; un rôle séparé crée la preuve. PLUTO apporte ainsi l'intelligence
> opérationnelle aux entreprises directement dans l'outil quotidien qu'est
> WhatsApp.

## Plan de secours

- Si Exa est indisponible, dire : « PLUTO le signale et n'invente pas de source ».
- Si le graphique échoue, montrer le résumé texte déjà envoyé.
- Si l'action échoue, montrer le message « non exécutée » et l'alerte admin ; ne
  jamais prétendre qu'elle est partie.
- Si Redis est indisponible, refaire une question complète : la lecture SQL
  continue et l'admin reçoit le diagnostic.
