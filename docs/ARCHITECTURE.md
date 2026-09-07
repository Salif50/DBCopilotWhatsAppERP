# Architecture

## Chaîne principale
WhatsApp → GOWA → Webhook n8n → normalisation → texte/vocal.

### Texte
Question → Text-to-SQL → validation → PostgreSQL read-only → synthèse → WhatsApp.

### Vocal
GOWA media `.ogg` → téléchargement → normalisation MIME → Whisper.
Si transcription valide, le flux rejoint Text-to-SQL.
Sinon, l'utilisateur reçoit un message lui demandant de reprendre le vocal ou d'envoyer du texte.

### Graphiques
La question est inspectée pour détecter une demande explicite de graphique.
Le LLM de synthèse reçoit `force_chart=true`.
Si les résultats sont graphiquables, QuickChart produit l'image, n8n la télécharge réellement, puis GOWA l'envoie sur WhatsApp.

## Modèle métier
Clients 1—N Ventes 1—N Vente_lignes N—1 Produits.
Fournisseurs 1—N Achats 1—N Achat_lignes N—1 Produits.
Produits 1—N Mouvements_stock.
