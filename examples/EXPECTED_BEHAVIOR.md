# Expected Behavior

- Business questions → safe SELECT.
- Voice → transcription → correction → SQL.
- Ambiguous voice → fallback message, no SQL.
- Explicit chart request → `force_chart=true`.
- Empty results → no invented data.
- Destructive SQL → refusal.
- Charts → JPG sent through GOWA.
