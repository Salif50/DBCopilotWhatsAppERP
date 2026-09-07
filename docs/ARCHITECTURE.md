# Architecture

WhatsApp → GOWA → n8n → text/audio → OpenAI → Text-to-SQL → SQL Guard → PostgreSQL read-only → synthesis → QuickChart → GOWA → WhatsApp.

The voice branch uses `gpt-4o-mini-transcribe`, followed by a business-vocabulary correction step before Text-to-SQL.

The chart branch separates `force_chart` from the analytical question, generates JPG with QuickChart, downloads it as binary, normalizes it as `image/jpeg`, then sends it through GOWA.
