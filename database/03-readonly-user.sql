DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='db_copilot_ro') THEN
   CREATE ROLE db_copilot_ro LOGIN;
 END IF;
 EXECUTE format('GRANT CONNECT ON DATABASE %I TO db_copilot_ro', current_database());
END $$;

GRANT USAGE ON SCHEMA public TO db_copilot_ro;
GRANT SELECT ON TABLE
 public.clients, public.fournisseurs, public.produits, public.ventes,
 public.vente_lignes, public.achats, public.achat_lignes,
 public.mouvements_stock, public.v_stock_produits
TO db_copilot_ro;

ALTER ROLE db_copilot_ro SET default_transaction_read_only = on;
ALTER ROLE db_copilot_ro SET statement_timeout = '8s';

-- Le mot de passe est injecté après ce script par scripts/bootstrap-docker.sh.
-- En installation manuelle : ALTER ROLE db_copilot_ro PASSWORD 'SECRET_FORT';
