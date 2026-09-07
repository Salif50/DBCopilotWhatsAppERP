# Project Description

DB Copilot WhatsApp is a secure conversational business-data agent that allows managers to query PostgreSQL ERP data directly from WhatsApp using natural-language text or voice and receive concise answers and charts.

The agent uses GOWA for WhatsApp, n8n for orchestration, OpenAI for voice transcription, business-context correction, Text-to-SQL and synthesis, PostgreSQL 16 for structured business data, and QuickChart for visualizations.

Generated SQL is never executed directly. A deterministic SQL guard enforces SELECT-only behavior, table allowlists, blocked PostgreSQL system catalogs/functions and result limits, while PostgreSQL uses a dedicated read-only role with a timeout.

Voice messages are transcribed using `gpt-4o-mini-transcribe`, then corrected against ERP vocabulary to reduce errors such as “achats” being transcribed as unrelated words. Ambiguous audio is safely rejected.

Visualization intent is separated from database intent. When the user asks for a chart, DB Copilot retrieves the analytical data first, then generates and sends a compatible JPG chart through WhatsApp.

Core principle: AI can propose an action, but deterministic controls decide whether that action is allowed.
