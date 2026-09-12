# Changelog

## v7.0.1 PLUTO Competition Agent

- Validation SQL par AST SQLGlot, puis préflight avec le parseur PostgreSQL.
- Autocorrection SQL bornée à un seul essai et repassage par toutes les validations.
- Mémoire conversationnelle Redis avec expiration et identifiants de chat hachés.
- Gestion des suivis comme « et pour le mois dernier ? » et « fais-en un graphique ».
- Seuil de confiance sur les alertes ventes et ruptures ; fin silencieuse sous le seuil.
- Journal d'actions PostgreSQL et credential dédiée sans droit métier ni modification.
- Commande manager `/audit` pour montrer les cinq dernières actions exécutées.
- Microservice interne `pluto-control` authentifié, sans exposition de port public.
- Pack de démo en quatre temps et matrice de tests de non-régression.
- README GitHub recentré sur l'expérience agentique et la démonstration jury.
- Bootstrap Docker reproductible avec injection des mots de passe depuis `.env`.
- Questions live pour la vidéo, scripts de validation et CI GitHub.

## v6.2 PLUTO Resilience

- Réponses de secours sur les chemins texte, audio, format et graphique.
- Préflight SQL avec le parseur PostgreSQL avant exécution.
- Approbation OUI ou NON fiable, expirant après 30 minutes.
- Commande manager `/demo-alerte` pour une démonstration reproductible.
- Superviseur séparé des erreurs n8n avec alerte WhatsApp sécurisée.
- Notification administrateur également pour les erreurs gérées par un fallback.
- Suppression des numéros et identifiants de session codés en dur.

## v6 PLUTO DB Copilot Autonomous
- OpenAI Responses API pour le Text-to-SQL et les sorties structurées
- routage multi-modèle avec gpt-5.6-terra et gpt-6-astra
- commandes WhatsApp `/aide`, `/enquete` et `/briefing`
- planification de 2 à 4 requêtes SQL complémentaires
- validation déterministe de chaque requête avant exécution
- enrichissement externe Exa avec sources visibles
- synthèse séparant faits, hypothèses et recommandations
- token d'approbation lié au chat et valable 30 minutes
- action externe impossible sans confirmation explicite
- surveillance toutes les 30 minutes et déduplication des alertes
- conservation intégrale du workflow v5

## v5 Voice Robust
- gpt-4o-mini-transcribe
- ERP vocabulary correction
- ambiguous transcription fallback
- secure multi-table Text-to-SQL
- explicit chart routing
- JPG/GOWA chart pipeline

## v4
- JPG image delivery

## v3
- visualization intent separated from analytical intent

## v2
- ERP multi-table schema and stronger SQL guard

## v1
- WhatsApp → SQL → PostgreSQL → WhatsApp prototype
