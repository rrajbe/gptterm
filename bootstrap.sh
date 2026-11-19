#!/bin/bash
# gptterm bootstrap for macOS: checks Chrome + Python, builds .venv, installs a `gptterm`
# command in ~/.local/bin, then runs a live check against chatgpt.com.
# Safe to run again at any time.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
bin_dir="$HOME/.local/bin"
say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m  %s\n' "$*"; }
fail() { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || fail "this bootstrap is for macOS"

say "1/5 Chromium browser"
browser=""
for pair in "com.google.Chrome:Google Chrome" "org.chromium.Chromium:Chromium" \
            "com.microsoft.edgemac:Microsoft Edge" "com.brave.Browser:Brave Browser"; do
  id="${pair%%:*}"; name="${pair#*:}"
  for d in "/Applications" "$HOME/Applications"; do
    [ -d "$d/$name.app" ] && { browser="$d/$name.app"; break 2; }
  done
  app="$(mdfind "kMDItemCFBundleIdentifier == '$id'" 2>/dev/null | head -1 || true)"
  [ -n "$app" ] && { browser="$app"; break; }
done
[ -n "${GPTTERM_BROWSER:-}" ] && browser="$GPTTERM_BROWSER"
if [ -z "$browser" ]; then
  if command -v brew >/dev/null; then
    read -r -p "    No Chrome found. Install Google Chrome with Homebrew now? [y/N] " a
    [[ "$a" =~ ^[Yy] ]] || fail "install Google Chrome from https://www.google.com/chrome/ and re-run"
    brew install --cask google-chrome
    browser="/Applications/Google Chrome.app"
  else
    fail "install Google Chrome from https://www.google.com/chrome/ and re-run"
  fi
fi
ok "$browser"

say "2/5 Python 3.9+"
py=""
for c in /opt/homebrew/bin/python3 /usr/local/bin/python3 python3; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
    py="$(command -v "$c")"; break
  fi
done
if [ -z "$py" ]; then
  fail "no Python 3.9+. Run: xcode-select --install   (or: brew install python), then re-run"
fi
ok "$py ($("$py" -V 2>&1))"

say "3/5 Python environment (.venv)"
if [ ! -x "$here/.venv/bin/python" ] || ! "$here/.venv/bin/python" -V >/dev/null 2>&1; then
  rm -rf "$here/.venv"
  "$py" -m venv "$here/.venv"
fi
"$here/.venv/bin/python" -m pip install -q --disable-pip-version-check -r "$here/requirements.txt"
ok "websocket-client, rich installed"

say "4/5 gptterm command"
chmod +x "$here/gptterm"
mkdir -p "$bin_dir"
ln -sf "$here/gptterm" "$bin_dir/gptterm"
ok "$bin_dir/gptterm -> $here/gptterm"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) printf '    add to your shell profile:  export PATH="$HOME/.local/bin:$PATH"\n' ;;
esac

say "5/5 live check (opens the dedicated gptterm Chrome window)"
"$here/gptterm" --check || fail "check failed; see $here/data/gptterm.log"

printf '\n\033[1;32mReady.\033[0m  Run: gptterm   (or gptterm --resume)\n'
