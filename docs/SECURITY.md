# Security

Defense in depth:
1. restrictive Text-to-SQL prompt
2. allowlisted ERP schema
3. SELECT-only rule
4. destructive SQL blocking
5. PostgreSQL system catalog/function blocking
6. canonical business-value normalization
7. result limits
8. PostgreSQL read-only user
9. `default_transaction_read_only=on`
10. `statement_timeout`
11. WhatsApp anti-loop
12. no admin database credentials in the agent

Production should additionally use WhatsApp user authorization, RLS, AST SQL parsing, auditing, rate limiting, centralized secrets and database separation.
