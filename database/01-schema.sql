-- DB Copilot ERP schema
CREATE TABLE IF NOT EXISTS clients (
 id_client BIGSERIAL PRIMARY KEY, code_client VARCHAR(30) UNIQUE NOT NULL,
 nom VARCHAR(150) NOT NULL, telephone VARCHAR(30), email VARCHAR(150), ville VARCHAR(50),
 adresse TEXT, type_client VARCHAR(30) NOT NULL DEFAULT 'ENTREPRISE'
 CHECK (type_client IN ('PARTICULIER','ENTREPRISE','ADMINISTRATION','ONG')),
 nif VARCHAR(100), actif BOOLEAN NOT NULL DEFAULT TRUE, date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fournisseurs (
 id_fournisseur BIGSERIAL PRIMARY KEY, code_fournisseur VARCHAR(30) UNIQUE NOT NULL,
 nom VARCHAR(150) NOT NULL, telephone VARCHAR(30), email VARCHAR(150), ville VARCHAR(100),
 pays VARCHAR(100) DEFAULT 'Guinée', adresse TEXT, contact_principal VARCHAR(150),
 nif VARCHAR(100), actif BOOLEAN NOT NULL DEFAULT TRUE, date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS produits (
 id_produit BIGSERIAL PRIMARY KEY, reference VARCHAR(50) UNIQUE NOT NULL, nom VARCHAR(150) NOT NULL,
 description TEXT, categorie VARCHAR(100), type_item VARCHAR(20) NOT NULL DEFAULT 'PRODUIT'
 CHECK (type_item IN ('PRODUIT','SERVICE')), unite VARCHAR(30) DEFAULT 'UNITE',
 prix_achat_gnf NUMERIC(15,2) CHECK (prix_achat_gnf >= 0),
 prix_vente_gnf NUMERIC(15,2) NOT NULL CHECK (prix_vente_gnf >= 0),
 stock_minimum NUMERIC(12,2) DEFAULT 0, stock_gere BOOLEAN NOT NULL DEFAULT TRUE,
 actif BOOLEAN NOT NULL DEFAULT TRUE, date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ventes (
 id_vente BIGSERIAL PRIMARY KEY, numero_vente VARCHAR(50) UNIQUE NOT NULL,
 id_client BIGINT NOT NULL REFERENCES clients(id_client), date_vente TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 statut VARCHAR(30) NOT NULL DEFAULT 'EN_ATTENTE' CHECK (statut IN ('PAYÉ','EN_ATTENTE','ANNULÉ','PARTIEL')),
 mode_paiement VARCHAR(30), montant_total_gnf NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (montant_total_gnf >= 0),
 montant_paye_gnf NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (montant_paye_gnf >= 0),
 commentaire TEXT, date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vente_lignes (
 id_ligne_vente BIGSERIAL PRIMARY KEY, id_vente BIGINT NOT NULL REFERENCES ventes(id_vente) ON DELETE CASCADE,
 id_produit BIGINT NOT NULL REFERENCES produits(id_produit), quantite NUMERIC(12,2) NOT NULL CHECK (quantite > 0),
 prix_unitaire_gnf NUMERIC(15,2) NOT NULL CHECK (prix_unitaire_gnf >= 0),
 remise_gnf NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (remise_gnf >= 0),
 total_ligne_gnf NUMERIC(15,2) GENERATED ALWAYS AS ((quantite * prix_unitaire_gnf) - remise_gnf) STORED
);

CREATE TABLE IF NOT EXISTS achats (
 id_achat BIGSERIAL PRIMARY KEY, numero_achat VARCHAR(50) UNIQUE NOT NULL,
 id_fournisseur BIGINT NOT NULL REFERENCES fournisseurs(id_fournisseur),
 date_achat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 statut VARCHAR(30) NOT NULL DEFAULT 'REÇU' CHECK (statut IN ('COMMANDE','REÇU','ANNULÉ','PARTIEL')),
 montant_total_gnf NUMERIC(15,2) NOT NULL DEFAULT 0, commentaire TEXT,
 date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS achat_lignes (
 id_ligne_achat BIGSERIAL PRIMARY KEY, id_achat BIGINT NOT NULL REFERENCES achats(id_achat) ON DELETE CASCADE,
 id_produit BIGINT NOT NULL REFERENCES produits(id_produit), quantite NUMERIC(12,2) NOT NULL CHECK (quantite > 0),
 prix_unitaire_gnf NUMERIC(15,2) NOT NULL CHECK (prix_unitaire_gnf >= 0),
 total_ligne_gnf NUMERIC(15,2) GENERATED ALWAYS AS (quantite * prix_unitaire_gnf) STORED
);

CREATE TABLE IF NOT EXISTS mouvements_stock (
 id_mouvement BIGSERIAL PRIMARY KEY, id_produit BIGINT NOT NULL REFERENCES produits(id_produit),
 type_mouvement VARCHAR(30) NOT NULL CHECK (type_mouvement IN ('ENTREE','SORTIE','AJUSTEMENT_POSITIF','AJUSTEMENT_NEGATIF')),
 quantite NUMERIC(12,2) NOT NULL CHECK (quantite > 0), id_vente BIGINT REFERENCES ventes(id_vente),
 id_achat BIGINT REFERENCES achats(id_achat), motif VARCHAR(150),
 date_mouvement TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, commentaire TEXT
);

CREATE OR REPLACE VIEW v_stock_produits AS
SELECT p.id_produit,p.reference,p.nom,p.categorie,p.stock_minimum,
 COALESCE(SUM(CASE WHEN m.type_mouvement IN ('ENTREE','AJUSTEMENT_POSITIF') THEN m.quantite
 WHEN m.type_mouvement IN ('SORTIE','AJUSTEMENT_NEGATIF') THEN -m.quantite ELSE 0 END),0) AS stock_actuel
FROM produits p LEFT JOIN mouvements_stock m ON m.id_produit=p.id_produit
WHERE p.stock_gere=TRUE
GROUP BY p.id_produit,p.reference,p.nom,p.categorie,p.stock_minimum;

CREATE INDEX IF NOT EXISTS idx_clients_ville ON clients(ville);
CREATE INDEX IF NOT EXISTS idx_produits_categorie ON produits(categorie);
CREATE INDEX IF NOT EXISTS idx_ventes_date ON ventes(date_vente);
CREATE INDEX IF NOT EXISTS idx_ventes_statut_date ON ventes(statut,date_vente);
CREATE INDEX IF NOT EXISTS idx_mouvements_produit ON mouvements_stock(id_produit);
