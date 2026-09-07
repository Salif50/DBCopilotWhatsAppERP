# Dépannage

## PostgreSQL: Connection refused ::1:5432
Dans n8n Docker, utiliser `postgres` comme host, pas `localhost`.

## Whisper: Unrecognized file format
Le workflow récupère `payload.audio`, télécharge `http://gowa:3000/statics/media/...ogg`, puis force `voice.ogg` et `audio/ogg`.

## Audio impossible à transcrire
Le workflow doit suivre la branche d'échec et envoyer un message demandant de reprendre le vocal.

## GOWA: unsupported file type
Ne pas donner seulement une URL QuickChart à `/send/image`. Télécharger d'abord l'image comme binaire PNG dans n8n puis l'envoyer selon le format attendu par GOWA.

## Aucun output après normalisation
GOWA envoie aussi `chat_presence`. Seuls les événements `message` sont traités.

## Credentials après import
Les credentials doivent être resélectionnés manuellement dans n8n. Ne jamais publier des IDs/secrets privés.
