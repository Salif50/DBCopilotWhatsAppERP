# DB_Copilot — Guide de test (commandes)

Carnet pratique pour charger la base, l'interroger, tester les détecteurs de
l'agent et la confirmation WhatsApp. Toutes les requêtes SQL ci‑dessous sont
celles réellement utilisées par le workflow (testées sur PostgreSQL 16).

> Contexte : base `n8n`, schéma `public`. Adapte l'hôte/port/utilisateur à ton
> installation. Si n8n et Postgres tournent dans Docker, utilise les variantes
> `docker exec` indiquées.

---

## 1. Charger la base (ordre impératif)

```bash
# Variante psql directe (Postgres accessible en local)
psql -h localhost -U postgres -d n8n -f 01-schema.sql
psql -h localhost -U postgres -d n8n -f 02-seed-demo.sql
psql -h localhost -U postgres -d n8n -f 05-hackathon-demo-data.sql
psql -h localhost -U postgres -d n8n -f 06-demo-scenario.sql   # scénario de démo propre
psql -h localhost -U postgres -d n8n -f 03-readonly-user.sql   # rôle lecture seule (en dernier)
```

```bash
# Variante Docker (si Postgres est dans un conteneur, ex. "postgres")
cat 01-schema.sql | docker exec -i postgres psql -U postgres -d n8n
cat 02-seed-demo.sql | docker exec -i postgres psql -U postgres -d n8n
cat 05-hackathon-demo-data.sql | docker exec -i postgres psql -U postgres -d n8n
cat 06-demo-scenario.sql | docker exec -i postgres psql -U postgres -d n8n
cat 03-readonly-user.sql | docker exec -i postgres psql -U postgres -d n8n
```

> ⚠️ Change le mot de passe du rôle lecture seule dans `03-readonly-user.sql`
> (`CHANGE_ME_DB_COPILOT`) avant de l'exécuter.

Ouvrir un shell SQL interactif :
```bash
psql -h localhost -U postgres -d n8n
# ou : docker exec -it postgres psql -U postgres -d n8n
```

---

## 2. Vérifier que les données sont bien là

```sql
-- Volumétrie
SELECT 'clients' t, COUNT(*) n FROM clients
UNION ALL SELECT 'produits', COUNT(*) FROM produits
UNION ALL SELECT 'ventes', COUNT(*) FROM ventes
UNION ALL SELECT 'mouvements_stock', COUNT(*) FROM mouvements_stock;

-- Aucun stock négatif ne doit rester (doit renvoyer 0)
SELECT COUNT(*) AS negatifs FROM v_stock_produits WHERE stock_actuel < 0;

-- Les 10 stocks les plus bas
SELECT nom, stock_minimum, stock_actuel
FROM v_stock_produits ORDER BY stock_actuel ASC LIMIT 10;
```

---

## 3. Tester les détecteurs de l'agent (requêtes exactes)

### 3.1 Détecteur de rupture de stock (le héros de la démo)

```sql
SELECT s.nom, s.stock_minimum, s.stock_actuel,
       ROUND(COALESCE(c.conso_jour,0),2) AS conso_jour,
       CASE WHEN COALESCE(c.conso_jour,0) > 0
            THEN ROUND(s.stock_actuel / c.conso_jour,1) END AS jours_avant_rupture
FROM v_stock_produits s
LEFT JOIN (
  SELECT id_produit, SUM(quantite)/14.0 AS conso_jour
  FROM mouvements_stock
  WHERE type_mouvement = 'SORTIE'
    AND date_mouvement >= CURRENT_DATE - INTERVAL '14 days'
  GROUP BY id_produit
) c ON c.id_produit = s.id_produit
WHERE s.stock_actuel <= s.stock_minimum
   OR (COALESCE(c.conso_jour,0) > 0 AND s.stock_actuel / c.conso_jour <= 3)
ORDER BY jours_avant_rupture NULLS LAST;
```
**Attendu (au 12/09/2026)** : 3 lignes — Écran Dell (~1,8 j), Laptop Dell (~2,3 j),
SSD 1TB (~3,5 j).

### 3.2 Recherche de la CAUSE (commande fournisseur en retard)

```sql
SELECT a.numero_achat, a.date_achat::date AS date_achat, f.nom AS fournisseur,
       f.telephone, string_agg(p.nom, ', ') AS produits
FROM achats a
JOIN fournisseurs f ON f.id_fournisseur = a.id_fournisseur
JOIN achat_lignes al ON al.id_achat = a.id_achat
JOIN produits p ON p.id_produit = al.id_produit
WHERE a.statut = 'COMMANDE'
  AND a.date_achat >= CURRENT_DATE - INTERVAL '20 days'
  AND EXISTS (SELECT 1 FROM achat_lignes al2
              JOIN v_stock_produits s ON s.id_produit = al2.id_produit
              WHERE al2.id_achat = a.id_achat AND s.stock_actuel <= s.stock_minimum)
GROUP BY a.numero_achat, a.date_achat, f.nom, f.telephone
ORDER BY a.date_achat DESC LIMIT 1;
```
**Attendu** : `DEMO-LATE-1209` du 04/09, « Guinée Informatique Distribution »,
3 produits.

### 3.3 Détecteur de chute des ventes (filet secondaire)

```sql
SELECT
 SUM(CASE WHEN date_vente >= CURRENT_DATE - INTERVAL '7 days'  THEN montant_total_gnf ELSE 0 END) AS s7,
 SUM(CASE WHEN date_vente >= CURRENT_DATE - INTERVAL '14 days'
          AND date_vente <  CURRENT_DATE - INTERVAL '7 days'   THEN montant_total_gnf ELSE 0 END) AS s14,
 ROUND(100.0 * (
   SUM(CASE WHEN date_vente >= CURRENT_DATE - INTERVAL '7 days' THEN montant_total_gnf ELSE 0 END)
 - SUM(CASE WHEN date_vente >= CURRENT_DATE - INTERVAL '14 days' AND date_vente < CURRENT_DATE - INTERVAL '7 days' THEN montant_total_gnf ELSE 0 END))
 / NULLIF(SUM(CASE WHEN date_vente >= CURRENT_DATE - INTERVAL '14 days' AND date_vente < CURRENT_DATE - INTERVAL '7 days' THEN montant_total_gnf ELSE 0 END),0),1) AS variation_pct
FROM ventes WHERE statut <> 'ANNULÉ';
```
**Attendu** : ~+7 % sur les données de démo → ce détecteur ne s'alerte PAS
(normal, il ne réagit qu'aux vraies baisses).

### 3.4 Enquête produit (ex. ventes des 3 phares, semaine vs semaine)

```sql
SELECT p.nom,
 SUM(CASE WHEN v.date_vente >= CURRENT_DATE - INTERVAL '7 days' THEN vl.quantite ELSE 0 END) AS qte_semaine,
 SUM(CASE WHEN v.date_vente >= CURRENT_DATE - INTERVAL '14 days' AND v.date_vente < CURRENT_DATE - INTERVAL '7 days' THEN vl.quantite ELSE 0 END) AS qte_prec
FROM vente_lignes vl
JOIN ventes v ON v.id_vente = vl.id_vente
JOIN produits p ON p.id_produit = vl.id_produit
WHERE p.reference IN ('PRD001','PRD006','PRD003') AND v.statut <> 'ANNULÉ'
GROUP BY p.nom;
```

---

## 4. Tester la sécurité lecture seule

```bash
# Connexion avec le rôle de l'agent
PGPASSWORD='TON_MOT_DE_PASSE_RO' psql -h localhost -U db_copilot_ro -d n8n
```
```sql
-- Doit RÉUSSIR
SELECT COUNT(*) FROM ventes;

-- Doit ÉCHOUER : « cannot execute INSERT in a read-only transaction »
INSERT INTO clients(code_client, nom) VALUES ('X','Test');

-- Doit être coupé après 8s (statement_timeout du rôle)
SELECT pg_sleep(20);
```

Le validateur SQL du workflow bloque aussi côté agent : toute requête non‑SELECT,
avec `;`, commentaire, `WITH`, `UNION` ou table hors périmètre est rejetée.

---

## 5. Importer et configurer le workflow n8n

1. **Importer** `DB_Copilot_Agent_Proactif_v6.json` (Workflows → Import from File).
2. **Credentials** à (re)sélectionner :
   - Postgres (lecture seule) sur les 3 nœuds `Scan ventes (RO)`,
     `Exécuter invest. (RO)`, `Scan stock (RO)` et `Chercher cause fournisseur (RO)`.
   - OpenAI (Bearer) et GOWA (Basic) : normalement re‑mappées automatiquement.
   - Créer une credential **Header Auth** pour Exa : nom d'en‑tête `x-api-key`,
     valeur = ta clé Exa ; la sélectionner sur `Exa - contexte externe`.
3. **Nœud `Paramètres surveillance`** : renseigner
   `MANAGER_PHONE` (ton numéro, ex. `224620000000`), `SESSION_ID` (ton X‑Device‑Id
   GOWA) et, si besoin, le seuil de baisse.
4. Pour la démo : dans `Cron Surveillance`, passer l'intervalle en **minutes**.

---

## 6. Déclencher la surveillance (test)

- **Manuel** : ouvrir le workflow → bouton **Test workflow**, ou clic droit sur
  `Cron Surveillance` → **Execute node**. Suivre le flux jusqu'à
  `Envoyer alerte rupture WhatsApp`.
- **Automatique** : **activer** le workflow (toggle Active) ; le Cron déclenchera
  seul. L'état « action en attente » (confirmation) n'est fiable que workflow
  **activé**.

Vérifier chaque nœud : cliquer dessus après l'exécution pour voir les données de
sortie (le message d'alerte construit apparaît sur `Préparer alerte rupture`).

---

## 7. Tester la confirmation WhatsApp sans téléphone (curl)

Le webhook d'entrée est `gowa-db-copilot`. On simule un message « OUI » du manager.
Remplace l'hôte, le port n8n, `SESSION_ID` et le numéro par les tiens.

```bash
# URL production : http://localhost:5678/webhook/gowa-db-copilot
# URL mode test  : http://localhost:5678/webhook-test/gowa-db-copilot  (workflow ouvert, "Listen")

curl -X POST http://localhost:5678/webhook/gowa-db-copilot \
 -H 'Content-Type: application/json' \
 -d '{
   "event": "message",
   "session_id": "REMPLACE_SESSION",
   "device_id": "REMPLACE_DEVICE",
   "timestamp": 1757660000,
   "payload": {
     "chat_id": "224620000000",
     "from": "224620000000",
     "from_name": "Manager",
     "id": "test-msg-1",
     "body": "OUI",
     "is_from_me": false,
     "is_group": false
   }
 }'
```

- `"body": "OUI"` → exécute l'action mémorisée (envoi de la relance).
- `"body": "NON"` → annule et efface l'action en attente.
- `"body": "Chiffre d'affaires du mois ?"` → repart dans ton flux réactif
  text‑to‑SQL existant (aucune action en attente).

> Pré‑requis : une action doit être « en attente » (donc lancer d'abord la
> surveillance de l'étape 6) pour que `OUI` ait quelque chose à exécuter.

Tester aussi le **mode vocal** existant en envoyant un vrai message vocal depuis
WhatsApp (Whisper → correction → SQL).

---

## 8. Réinitialiser la démo

```sql
TRUNCATE public.mouvements_stock, public.vente_lignes, public.ventes,
         public.achat_lignes, public.achats, public.produits,
         public.fournisseurs, public.clients RESTART IDENTITY CASCADE;
```
Puis relancer `02-seed-demo.sql`, `05-hackathon-demo-data.sql`,
`06-demo-scenario.sql`. (Le patch `06` n'est pas ré‑exécutable seul : il ajoute
de la consommation à chaque passage — repartir d'un TRUNCATE.)

---

## 9. Dépannage rapide

- **Le détecteur rupture ne renvoie rien** : la démo est datée pour le
  **12/09/2026** ; exécute‑la ce jour‑là, sinon la fenêtre « 14 derniers jours »
  se décale et le taux de consommation retombe. Sinon, redate les mouvements
  récents de `06`.
- **Erreur Postgres « read-only transaction »** sur un nœud : normal si tu as mis
  le rôle `db_copilot_ro` — c'est voulu pour les lectures ; garde ce rôle sur les
  nœuds de scan.
- **Exa renvoie une erreur** : l'alerte part quand même (le nœud est en
  `continue on error`) ; vérifie la credential Header Auth `x-api-key`.
- **`OUI` ne déclenche rien** : aucune action en attente — relance d'abord la
  surveillance, et assure‑toi que le workflow est **activé** (sinon l'état n'est
  pas persisté).
- **GOWA n'envoie pas** : vérifie l'URL `http://gowa:3000/send/message`, le header
  `X-Device-Id` (= `SESSION_ID`) et la credential Basic.
```
