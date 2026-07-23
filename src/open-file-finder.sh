#!/usr/bin/env bash
# herdr-file-finder action launcher — runs OUTSIDE the pane (herdr action context).
#
# Opens the file-finder entrypoint as a focused overlay pane, rooted at the
# focused pane's cwd (falling back to the workspace cwd) so the search covers
# the directory the user is actually working in. Context comes from the
# HERDR_PLUGIN_CONTEXT_JSON herdr injects (same contract reviewr uses).
set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
herdr_bin="${HERDR_BIN_PATH:-herdr}"

ws="${HERDR_WORKSPACE_ID:-}"
cwd=""
[ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ] &&
  cwd=$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" |
    jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null)

# Note: popup/overlay panes always target the ACTIVE pane — passing --workspace
# is rejected by herdr ("overlay and popup plugin panes target the active pane").
args=(plugin pane open
  --plugin herdr-file-finder
  --entrypoint file-finder
  --placement popup
  --width 70%
  --height 60%
  --focus)
[ -n "$cwd" ] && args+=(--cwd "$cwd")

exec "$herdr_bin" "${args[@]}"
