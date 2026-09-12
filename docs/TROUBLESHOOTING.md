# Troubleshooting

- `Connection refused ::1:5432`: use `postgres`, not localhost.
- no output after normalization: `chat_presence` is ignored; wait for `event=message`.
- audio format error: binary should be `voice.ogg`, `audio/ogg`.
- bad business transcription: PLUTO uses a dedicated vocabulary-correction step.
- wrong SQL status: use canonical values such as `PAYÉ`.
- JSON mode error: synthesis prompt explicitly requests JSON.
- image format error: final branch uses JPG / `image/jpeg`.
