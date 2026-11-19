# Changelog

## 0.0.1 — 2026-11-19
First release.
- Terminal chat with logged-out chatgpt.com through a dedicated local Chrome (private tab, CDP).
- Streamed answers rendered as coloured markdown; `--plain` for raw text.
- One JSONL transcript per conversation in `data/sessions/`.
- `--resume` reattaches to the live tab, or continues the conversation from saved state after
  Chrome was closed.
- Streaming-safe saving: your message is written at once, the answer is snapshotted every 2 s and
  written on every ending (complete, Ctrl-C, SIGTERM/SIGHUP, lost Chrome, crash recovery).
  Answers that chatgpt.com shrinks or blanks after streaming are kept in full (`retracted`).
- Stops with a screenshot when chatgpt.com refuses a message (logged-out cap).
- `bootstrap.sh` sets up a fresh Mac; `--check`, `--quit-browser`, `--list`, `--version`.
