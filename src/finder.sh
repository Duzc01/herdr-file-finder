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
# Two levels, most specific wins:
#   [open_by_ext]  per-extension templates, e.g.  html = 'open "{path}"'
#   open = '…'     the fallback template for any other extension
# Placeholders: {uri} = percent-encoded absolute path, {path} = raw absolute
# path, {dir} = containing directory. Single-line TOML string only; a
# single-quoted literal string is preferred (templates contain `"` themselves).

# cfg_lookup <file> <section> <key> — print the (unquoted) value, or nothing.
# section="" matches top-level keys (those before any [header]).
cfg_lookup() {
  local file=$1 want_section=$2 want_key=$3 cur_section="" line trimmed k v
  while IFS= read -r line || [ -n "$line" ]; do
    trimmed=${line#"${line%%[![:space:]]*}"}
    case "$trimmed" in ''|'#'*) continue ;; esac
    if [[ $trimmed == '['*']'* ]]; then
      cur_section=${trimmed#\[}; cur_section=${cur_section%%\]*}
      cur_section=${cur_section#"${cur_section%%[![:space:]]*}"}
      cur_section=${cur_section%"${cur_section##*[![:space:]]}"}
      continue
    fi
    [ "$cur_section" = "$want_section" ] || continue
    [[ $trimmed == *=* ]] || continue
    k=${trimmed%%=*}; v=${trimmed#*=}
    k=${k#"${k%%[![:space:]]*}"}; k=${k%"${k##*[![:space:]]}"}
    [ "$k" = "$want_key" ] || continue
    v=${v#"${v%%[![:space:]]*}"}                       # left-trim
    case $v in
      \'*) v=${v#\'}; v=${v%%\'*} ;;                    # single-quoted literal
      \"*) v=${v#\"}; v=${v%\"*}; v=${v//\\\"/\"}; v=${v//\\\\/\\} ;;  # double-quoted
      *)   v=${v%%#*}; v=${v%"${v##*[![:space:]]}"} ;;  # bare: drop inline comment + right-trim
    esac
    printf '%s' "$v"; return 0
  done < "$file"
  return 1
}

template='open "warp://action/new_tab?path={uri}"'
cfg="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/herdr-file-finder}/config.toml"
if [ -f "$cfg" ]; then
  # Lowercased extension of the selected file (empty if it has none).
  base=${selected##*/}
  ext=""
  case "$base" in *.*) ext=$(printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]') ;; esac
  custom=""
  [ -n "$ext" ] && custom=$(cfg_lookup "$cfg" "open_by_ext" "$ext")
  [ -n "$custom" ] || custom=$(cfg_lookup "$cfg" "" "open")
  [ -n "$custom" ] && template="$custom"
fi

cmd=${template//\{uri\}/$encoded}
cmd=${cmd//\{path\}/$abs}
cmd=${cmd//\{dir\}/$PWD}

exec bash -c "$cmd"
