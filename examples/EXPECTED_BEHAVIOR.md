# Comportements attendus

- Les questions métier déclenchent uniquement des SELECT.
- Les réponses utilisent les données PostgreSQL réellement retournées.
- Les montants sont présentés en GNF.
- Une demande explicite de graphique active `force_chart`.
- Une note vocale valide rejoint exactement le même pipeline que le texte.
- Une transcription vide ou en erreur déclenche le message de reprise audio.
- Une commande destructive n'est jamais exécutée.
- Une question hors schéma retourne un refus fonctionnel, pas une requête inventée.
