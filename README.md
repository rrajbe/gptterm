# gptterm

Terminal chat with logged-out chatgpt.com: answers stream in as coloured markdown, and every
conversation is saved as JSONL. Install on a Mac: see [INSTALL.md](INSTALL.md) (`./bootstrap.sh`).

```
gptterm                  # new conversation
gptterm --resume         # continue the last conversation
gptterm --resume ID      # continue a specific one
gptterm --list           # saved conversations
gptterm --check          # start the gptterm Chrome, load chatgpt.com, report ready
gptterm --quit-browser   # close the gptterm Chrome
gptterm --plain          # raw markdown, no colours (automatic when piped)
gptterm --raw -v         # also keep raw ndjson in data/raw/, debug log
```
In the chat: end a line with `\` to continue on the next line; `/new`, `/id`, `/quit`.
Ctrl-C while an answer streams stops it; Ctrl-C/Ctrl-D at the prompt exits.

## How it works
chatgpt.com requires a fresh Cloudflare Turnstile + proof-of-work token on every turn, so gptterm
does not talk HTTP itself. It runs a **dedicated local Chrome** (own profile, debugging port
9333 on 127.0.0.1) and keeps one long-lived **private browser context + tab** in it. The page
does its own checks; gptterm types the prompt into it and reads the answer stream
(`/unauth-mweb/conversation/updates`, ndjson) through the Chrome DevTools Protocol.
Protocol details: [PROTOCOL.md](PROTOCOL.md).

- The private tab survives between gptterm runs, so `--resume` normally just reattaches.
- If the Chrome was closed, gptterm starts it again, restores the saved cookies into a new private
  context, and grafts the saved `conversationState` onto the next message, which continues the
  same conversation on chatgpt.com.

## How transcripts are saved
gptterm reads the answer from the network stream, not from the page, so an answer that the
page later fails to show is still captured. Nothing is lost when a turn goes wrong:

| moment | what is written |
|---|---|
| message sent (once the conversation id is known) | your `user` line |
| while the answer streams | `data/inflight.json`, overwritten every 2 s with the answer so far (one small file, no duplicate lines) |
| answer ends, however it ends | one `assistant` line, then `inflight.json` is removed |
| next start after a hard crash (`kill -9`, power loss) | the leftover `inflight.json` is added to the transcript |

The `assistant` line's `text` is always the **fullest answer streamed**. Extra fields:
- `"retracted": true` and `"final_text"`: chatgpt.com shrank or blanked the answer after streaming it. `text` keeps the full version, `final_text` is what the page ended with.
- `"incomplete": true` and `"reason"`: the answer didn't finish. The reason is one of: Ctrl-C, gptterm terminated (SIGTERM/SIGHUP), lost connection to Chrome, a stream error, the message wasn't accepted, or recovery from a crash snapshot.

## Files
| path | what |
|---|---|
| `data/sessions/<conversation-id>.jsonl` | transcript: one `{"ts","role","conversation_id","text",...}` per line; assistant lines add `message_id`, `first_token_s`, `total_s` |
| `data/state.json` | private context/tab ids, cookies, last conversation, saved conversationState per conversation |
| `data/inflight.json` | only while an answer streams: crash-recovery snapshot |
| `data/gptterm.log` | log (`-v` for debug) |
| `data/debug/` | screenshot + page text whenever ChatGPT refuses a message |

## Limits
- Logged-out ChatGPT has a message cap. When a message isn't accepted, gptterm stops, prints what
  the page says, and saves a screenshot in `data/debug/`. The transcript stays.
- One gptterm at a time per data folder (one tab, one conversation).
