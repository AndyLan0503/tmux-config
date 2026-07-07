#!/bin/bash
# Claude Code statusLine hook.
#
# Reads Claude's session JSON on stdin, runs cc-statusline, and tees the
# rendered status line to a cache file so tmux can mirror it in its
# status bar.
#
# Wire this into ~/.claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "~/repos/tmux-config/scripts/claude-statusline.sh",
#     "padding": 0,
#     "refreshInterval": 10
#   }
#
# Cache file is picked up by scripts/tmux-agent.sh (see tmux.conf).
set -euo pipefail

OUT_FILE="${TMPDIR:-/tmp}/agent-cache-claude.out"

npx -y @dartchuk-s/cc-statusline@latest | tee "$OUT_FILE"
