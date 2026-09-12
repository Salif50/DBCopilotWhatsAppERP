-- PLUTO DB Copilot - journal d'actions à permission minimale

CREATE TABLE IF NOT EXISTS public.pluto_action_audit (
    id_audit BIGSERIAL PRIMARY KEY,
    approval_id TEXT NOT NULL UNIQUE,
    approved_by_hash VARCHAR(64) NOT NULL,
    action_label TEXT NOT NULL,
    destination_last4 VARCHAR(4),
    channel VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
    status VARCHAR(20) NOT NULL CHECK (status IN ('EXECUTED', 'FAILED', 'CANCELLED')),
    requested_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    executed_at TIMESTAMPTZ,
    execution_reference TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pluto_action_audit_created_at
    ON public.pluto_action_audit (created_at DESC);

CREATE OR REPLACE VIEW public.v_pluto_action_audit AS
SELECT
    id_audit,
    approval_id,
    action_label,
    destination_last4,
    channel,
    status,
    approved_at,
    executed_at,
    execution_reference
FROM public.pluto_action_audit
ORDER BY created_at DESC;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db_copilot_audit') THEN
        CREATE ROLE db_copilot_audit LOGIN;
    END IF;
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO db_copilot_audit', current_database());
END
$$;

GRANT USAGE ON SCHEMA public TO db_copilot_audit;
GRANT INSERT, SELECT ON public.pluto_action_audit TO db_copilot_audit;
GRANT SELECT ON public.v_pluto_action_audit TO db_copilot_audit;
GRANT USAGE, SELECT ON SEQUENCE public.pluto_action_audit_id_audit_seq TO db_copilot_audit;

REVOKE UPDATE, DELETE, TRUNCATE ON public.pluto_action_audit FROM db_copilot_audit;
ALTER ROLE db_copilot_audit SET statement_timeout = '3s';

COMMENT ON TABLE public.pluto_action_audit IS
    'Journal immuable des actions PLUTO exécutées après approbation humaine.';

-- Le mot de passe est injecté après ce script par scripts/bootstrap-docker.sh.
-- En installation manuelle : ALTER ROLE db_copilot_audit PASSWORD 'SECRET_FORT';
