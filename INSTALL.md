# Installing gptterm on a Mac

## What you need
| # | Item | Notes |
|---|---|---|
| 1 | macOS | any recent version (tested on macOS 27) |
| 2 | Google Chrome | or Chromium / Microsoft Edge / Brave. The bootstrap offers to install Chrome with Homebrew if none is found |
| 3 | Python 3.9 or newer | the one from `xcode-select --install` (3.9) is enough; Homebrew Python also works |
| 4 | Internet access to chatgpt.com | from a country where logged-out ChatGPT is available |

No ssh, VM or account is needed.

## Steps
1. Copy these files into one folder on the new Mac (for example `~/gptterm`):
   `gptterm`, `gptterm.py`, `cdp.py`, `bootstrap.sh`, `requirements.txt`, `README.md`, `INSTALL.md`, `PROTOCOL.md`.
   Do **not** copy `.venv/`. Copy `data/sessions/` only if you want old transcripts; never copy
   `data/state.json` (it points at the old machine's browser).
2. If Python is missing, install Apple's command-line tools first:
   ```bash
   xcode-select --install
   ```
3. Run the bootstrap from that folder:
   ```bash
   cd ~/gptterm && ./bootstrap.sh
   ```
   It checks for a browser and Python, builds `.venv` with the two libraries in
   `requirements.txt`, links a `gptterm` command into `~/.local/bin`, and runs `gptterm --check`,
   which opens the dedicated gptterm Chrome window and loads chatgpt.com.
4. If it prints the `export PATH=...` line, add that line to `~/.zshrc` and open a new terminal.
5. Chat:
   ```bash
   gptterm
   ```

Re-running `./bootstrap.sh` is safe; use it after moving the folder or updating the files.

## The gptterm Chrome window
gptterm starts its own Chrome with a separate profile
(`~/Library/Application Support/gptterm/chrome-profile`) and a debugging port (9333) bound to
127.0.0.1 only. It never touches your normal Chrome profile or windows. Leave that window open
(minimising is fine) so `--resume` can reattach instantly; `gptterm --quit-browser` closes it.
If it is closed, the next gptterm run starts it again and `--resume` still continues the
conversation from saved state.

## Settings (environment variables, all optional)
| variable | default |
|---|---|
| `GPTTERM_BROWSER` | auto-detected Chrome → Chromium → Edge → Brave (path to the browser binary) |
| `GPTTERM_PORT` | `9333` |
| `GPTTERM_PROFILE` | `~/Library/Application Support/gptterm/chrome-profile` |
| `GPTTERM_DATA` | `<gptterm folder>/data` (transcripts, state, log) |

## Uninstall
```bash
gptterm --quit-browser; rm ~/.local/bin/gptterm; rm -rf ~/Library/Application\ Support/gptterm
```
then delete the gptterm folder (it holds your transcripts in `data/sessions/`).
