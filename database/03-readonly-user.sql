DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='db_copilot_ro') THEN
   CREATE ROLE db_copilot_ro LOGIN PASSWORD 'CHANGE_ME_DB_COPILOT';
 END IF;
END $$;

GRANT CONNECT ON DATABASE n8n TO db_copilot_ro;
GRANT USAGE ON SCHEMA public TO db_copilot_ro;
GRANT SELECT ON TABLE
 public.clients, public.fournisseurs, public.produits, public.ventes,
 public.vente_lignes, public.achats, public.achat_lignes,
 public.mouvements_stock, public.v_stock_produits
TO db_copilot_ro;

ALTER ROLE db_copilot_ro SET default_transaction_read_only = on;
ALTER ROLE db_copilot_ro SET statement_timeout = '8s';
