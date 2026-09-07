# Technical Decisions

- WhatsApp: existing daily-work channel.
- n8n: transparent orchestration and fast iteration.
- separate LLM roles: SQL generation vs synthesis.
- voice correction: protects against business vocabulary transcription errors.
- read-only PostgreSQL: prompt safety is not enough.
- JPG charts: more reliable with the current GOWA image pipeline.
- deterministic validation: AI proposes; controls authorize.
