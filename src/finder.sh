#!/usr/bin/env bash
# herdr-file-finder pane entrypoint — runs INSIDE the herdr overlay pane.
#
# fd (gitignore-aware) feeds fzf; the selected file is handed to Warp via its
# `warp://action/new_tab?path=…` URI, which opens a new Warp tab routed by file
# type: Markdown → Warp's rendered notebook viewer, code/text → built-in editor,
# directories → a shell session. Esc / no selection just closes the overlay
# (herdr removes the pane when this process exits).
set -uo pipefail

# herdr runs plugin commands with a minimal PATH; ensure brew tools resolve.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

missing=""
command -v fd  >/dev/null 2>&1 || missing="$missing fd"
command -v fzf >/dev/null 2>&1 || missing="$missing fzf"
command -v jq  >/dev/null 2>&1 || missing="$missing jq"
if [ -n "$missing" ]; then
  printf 'herdr-file-finder: missing tools:%s\n  brew install%s\n' "$missing" "$missing"
  printf 'press Enter to close'
  read -r _
  exit 1
fi

preview='bat --color=always --style=numbers --paging=never {} 2>/dev/null || cat {}'
selected=$(fd --type f | fzf --scheme=path \
  --preview "$preview" --preview-window 'right,60%,border-left') || exit 0
[ -n "$selected" ] || exit 0

# Build an absolute path and percent-encode it for the URI (Chinese paths must
# be encoded; jq's @uri does full percent-encoding).
abs="$PWD/$selected"
encoded=$(jq -rn --arg p "$abs" '$p | @uri') || exit 1

# The open action is a command template from the plugin config (trusted,
# operator-configured — same contract as herdr-file-viewer's `markdown` key):
#   ~/.config/herdr/plugins/config/herdr-file-finder/config.toml
#     open = 'open "warp://action/new_tab?path={uri}"'
# Placeholders: {uri} = percent-encoded absolute path, {path} = raw absolute
# path, {dir} = containing directory. Single-line TOML string only; a
# single-quoted literal string is preferred (templates contain `"` themselves).
template='open "warp://action/new_tab?path={uri}"'
cfg="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/herdr-file-finder}/config.toml"
if [ -f "$cfg" ]; then
  custom=$(sed -nE "s/^[[:space:]]*open[[:space:]]*=[[:space:]]*'(.*)'[[:space:]]*\$/\\1/p" "$cfg" | head -1)
  if [ -z "$custom" ]; then
    custom=$(sed -nE 's/^[[:space:]]*open[[:space:]]*=[[:space:]]*"(.*)"[[:space:]]*$/\1/p' "$cfg" | head -1)
    # Unescape TOML basic-string escapes (\" then \\, in that order).
    custom=${custom//\\\"/\"}
    custom=${custom//\\\\/\\}
  fi
  [ -n "$custom" ] && template="$custom"
fi

cmd=${template//\{uri\}/$encoded}
cmd=${cmd//\{path\}/$abs}
cmd=${cmd//\{dir\}/$PWD}

exec bash -c "$cmd"
