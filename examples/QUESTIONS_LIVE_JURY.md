# Questions live pour la vidéo et le jury

Ce conducteur est conçu pour une vidéo de **4 à 6 minutes**. Il montre une
progression : réponse fiable, mémoire, visualisation, sécurité, proactivité,
contrôle humain et preuve d'action.

## Préparation avant d'enregistrer

- Lancer `./scripts/bootstrap-docker.sh --demo` sur une base propre.
- Vérifier que les deux workflows v7 sont actifs.
- Utiliser un téléphone manager et un second téléphone de l'équipe comme
  `PLUTO_DEMO_ACTION_PHONE`.
- Mettre `PLUTO_PROACTIVE_CONFIDENCE_MIN=75`.
- Envoyer `/demo-alerte`, répondre `NON`, puis vérifier que tout fonctionne.
- Effacer ou masquer les notifications sensibles avant la capture d'écran.
- Fermer les onglets affichant clés API, credentials ou vrais numéros.

## Séquence principale à filmer

### Scène 1 — Question métier directe

**Question WhatsApp**

> Quel est notre chiffre d'affaires payé ce mois-ci ?

**Ce que le jury doit voir**

- accusé de réception immédiat ;
- réponse chiffrée issue de PostgreSQL ;
- formulation courte adaptée à un manager.

**Phrase orale**

> PLUTO donne aux dirigeants un accès immédiat à leurs données sans ouvrir un
> ERP, écrire du SQL ou attendre un analyste.

### Scène 2 — Mémoire conversationnelle

**Question WhatsApp**

> Et pour le mois dernier ?

**Ce que le jury doit voir**

PLUTO comprend « et » et la période sans obliger l'utilisateur à reformuler la
question complète.

**Phrase orale**

> Redis conserve seulement le contexte utile avec expiration ; les lignes de la
> base métier ne sont pas copiées dans la mémoire.

### Scène 3 — Visualisation naturelle

**Question WhatsApp**

> Fais-en un graphique.

**Ce que le jury doit voir**

Le même sujet conversationnel devient un graphique reçu directement dans
WhatsApp.

**Phrase orale**

> Le graphique n'est pas une image inventée par l'IA : il est construit à partir
> du résultat SQL contrôlé.

### Scène 4 — Analyse plus complexe

**Question WhatsApp**

> Quelles sont les trois villes qui génèrent le plus de chiffre d'affaires payé,
> et quelle part du total représente chacune ?

**Ce que le jury doit voir**

Une agrégation, un classement et une synthèse décisionnelle, sans exposer les
téléphones ou adresses des clients.

### Scène 5 — Démonstration de sécurité

**Question WhatsApp**

> Supprime toutes les ventes annulées de la base.

**Résultat obligatoire**

Refus clair. Aucun SQL d'écriture ne doit atteindre PostgreSQL.

**Phrase orale**

> Même si un utilisateur demande une suppression, quatre barrières protègent la
> base : garde déterministe, AST, préflight PostgreSQL et rôle read-only.

### Scène 6 — Passage de l'assistant à l'agent

**Commande WhatsApp depuis le manager**

> /demo-alerte

**Ce que le jury doit voir**

- mention explicite « démonstration contrôlée » ;
- signal et chiffres réels ;
- cause probable ;
- confiance et seuil ;
- action proposée ;
- référence d'autorisation ;
- choix OUI/NON.

**Phrase orale**

> En production, PLUTO vit en arrière-plan. Il surveille ventes et stocks, mais
> il reste silencieux si le signal est faible. Cette commande rend simplement la
> démonstration reproductible devant le jury.

### Scène 7 — Action humaine contrôlée

**Réponse WhatsApp**

> OUI

Filmer simultanément ou en plan coupé le second téléphone recevant réellement
le message.

**Résultat obligatoire**

- l'action arrive sur le numéro de test ;
- la confirmation PLUTO vient après le succès réel ;
- la référence correspond à celle proposée.

**Phrase orale**

> Le modèle n'a pas le droit d'agir. L'autorisation doit venir du même chat,
> correspondre à OUI et arriver avant l'expiration de trente minutes.

### Scène 8 — Preuve et audit

**Commande WhatsApp**

> /audit

**Ce que le jury doit voir**

La dernière action avec son libellé, son statut, son horodatage, la fin du numéro
et la référence d'exécution.

**Phrase de conclusion**

> Le LLM propose, l'humain autorise, une règle déterministe exécute et un rôle
> PostgreSQL séparé crée la preuve. C'est ainsi que PLUTO apporte une IA
> opérationnelle et responsable dans l'outil quotidien qu'est WhatsApp.

## Questions supplémentaires si le jury demande plus

### Finance

> Compare le montant facturé et le montant réellement encaissé ce mois-ci.

> Quels sont les cinq clients qui génèrent le plus de chiffre d'affaires payé ?

> Montre l'évolution mensuelle du chiffre d'affaires depuis janvier.

### Ventes et géographie

> Fais un graphique du chiffre d'affaires payé par ville.

> Compare Conakry aux autres villes sur les trois derniers mois.

> Quels produits ont le plus contribué au chiffre d'affaires cette année ?

### Stocks et fournisseurs

> Quels produits sont sous leur stock minimum ?

> Parmi les produits en rupture, lesquels ont une commande fournisseur non reçue ?

> Quel fournisseur représente le plus d'achats reçus ?

### Marge et décision

> Classe les cinq produits avec la meilleure marge approximative.

> Quel service a généré le plus de revenus depuis août ?

> Résume en trois décisions les informations les plus importantes de ce mois.

## Tests de contrôle humain à montrer sur demande

| Action du jury | Résultat attendu |
|---|---|
| Répondre `peut-être` | PLUTO demande OUI ou NON, aucune action |
| Répondre `NON` | annulation confirmée |
| Répondre OUI depuis un autre numéro | aucune exécution de l'autorisation manager |
| Attendre plus de 30 minutes | autorisation expirée |
| Lancer `/audit` hors du chat manager | accès refusé |
| Couper Exa | PLUTO signale l'absence de contexte externe sans inventer de source |

## Questions à éviter dans la vidéo principale

- une période absente du jeu de données ;
- une demande exigeant une table non incluse dans le schéma ;
- une question volontairement vague avant d'avoir montré le flux fiable ;
- un envoi vers le numéro réel d'un client ou fournisseur ;
- une promesse d'action tant que le second téléphone ne l'a pas reçue.

## Plan B si un composant externe échoue

- **QuickChart** : montrer la réponse texte déjà reçue.
- **Exa** : souligner que PLUTO déclare la source indisponible.
- **OpenAI** : montrer l'alerte administrateur et expliquer le fallback.
- **GOWA lors de l'action** : montrer « action non exécutée » ; ne jamais annoncer
  un succès fictif.
- **Redis** : poser de nouveau la question complète ; la lecture métier reste
  disponible et l'administrateur reçoit le diagnostic.
