#!/bin/bash
# tmux status-bar reader — picks the freshest agent cache and emits
# line 1 for tmux's window-status-current-format.
#
# Convention: each agent script writes its status line to
# $TMPDIR/agent-cache-<name>.out. This reader:
#
#   1. Scans every agent-cache-*.out in $TMPDIR
#   2. Skips files older than 60s (stale — agent probably not running)
#   3. Picks the most recently modified one
#   4. Strips ANSI escapes (tmux #() output is rendered literally)
#   5. Prints line 1
#
# On a machine with no agent scripts installed, no cache files exist and
# the script exits silently. tmux shows a blank center region, no errors.
set -euo pipefail

TMP="${TMPDIR:-/tmp}"

freshest=""
freshest_mtime=0

for f in "$TMP"/agent-cache-*.out; do
  [[ -f $f ]] || continue
  # Skip if not modified in the last 60s.
  [[ -n "$(find "$f" -mmin -1 2>/dev/null)" ]] || continue
  # Portable mtime read (BSD stat on macOS, GNU stat on Linux).
  mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  if (( mtime > freshest_mtime )); then
    freshest_mtime=$mtime
    freshest=$f
  fi
done

[[ -n $freshest ]] || exit 0

line=$(head -1 "$freshest")
printf '%s' "$line" | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g'
