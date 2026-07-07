#!/bin/bash
# Codex CLI status hook (SCAFFOLD).
#
# Codex CLI does not currently expose a native "statusLine" hook
# analogous to Claude Code's, so this script fills the cache by polling.
# It's meant to be invoked either:
#
#   a. On a tmux status-interval cycle (call it from tmux-agent.sh, or
#      add a background poller — see README).
#   b. From a Codex hook once one becomes available. Enable hooks in
#      ~/.codex/config.toml:
#          [features]
#          hooks = true
#      and point the appropriate hook here.
#
# Contract: write a single-line status string to $OUT_FILE and exit. Any
# ANSI escapes are stripped by tmux-agent.sh, so feel free to colorize.
# If there's nothing meaningful to report, don't touch the file — that
# way stale data expires naturally (tmux-agent.sh ignores files older
# than 60s).
#
# TODO: once Codex exposes session/context/quota info (transcript path,
# model, token counts), fill this in with the same fields as Claude —
# model, context %, quota, session cost.
set -euo pipefail

OUT_FILE="${TMPDIR:-/tmp}/agent-cache-codex.out"

# Minimal working implementation: detect a running Codex CLI process and
# emit a bare "Codex: active" indicator. Replace this block with real
# session parsing once Codex exposes richer state.
if pgrep -x codex >/dev/null 2>&1 || pgrep -f '^codex( |$)' >/dev/null 2>&1; then
  printf 'Codex: active' > "$OUT_FILE"
fi
