# tmux-config

My tmux configuration. Prefix is `Ctrl-s`, vi-style copy mode, vim-tmux-navigator wired up for seamless nvim-tmux pane navigation, resurrect + continuum for layout persistence across restarts, and a centered status bar that mirrors Claude Code's `cc-statusline`.

## Setup after `git clone`

### 1. Clone the repo

```bash
git clone https://github.com/AndyLan0503/tmux-config ~/repos/tmux-config
```

### 2. Symlink the config to `~/.tmux.conf`

```bash
ln -s ~/repos/tmux-config/tmux.conf ~/.tmux.conf
```

If `~/.tmux.conf` already exists, back it up first:

```bash
mv ~/.tmux.conf ~/.tmux.conf.bak
ln -s ~/repos/tmux-config/tmux.conf ~/.tmux.conf
```

### 3. Install TPM (tmux plugin manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 4. Install plugins

Start tmux, then inside a session press the prefix followed by capital `I`:

```
Ctrl-s I
```

TPM will clone every plugin declared in `tmux.conf`:

- `tmux-plugins/tmux-sensible` — sane defaults
- `christoomey/vim-tmux-navigator` — `Ctrl-h/j/k/l` hops between nvim splits and tmux panes
- `samleeney/tmux-agent-status` — Claude Code agent activity indicator
- `tmux-plugins/tmux-resurrect` — save/restore sessions
- `tmux-plugins/tmux-continuum` — auto-save every 15 min, auto-restore on start

### 5. macOS-specific prerequisites

`samleeney/tmux-agent-status` uses features unavailable in the system's ancient bash 3.2:

```bash
brew install bash
```

The plugin auto-detects Homebrew bash at `/opt/homebrew/bin/bash`.

### 6. Optional: Claude Code statusline mirror

> The tmux config is agent-harness agnostic. If you skip this section, the center of the status bar is blank and no errors are printed — every other feature (splits, copy mode, resurrect, vim-tmux-navigator, etc.) works untouched. The `for` loop in `window-status-current-format` will pick up any executable statusline dropped at one of its candidate paths; add more paths there if you use Codex, Aider, etc.

The status bar centers `cc-statusline` output — model, context %, 5h/7d quota, session cost. That requires two Claude Code hooks:

**a. Wrapper that captures cc-statusline for tmux:**

Create `~/.claude/cc-statusline-wrapper.sh`:

```bash
#!/bin/bash
set -euo pipefail
OUT_FILE="${TMPDIR:-/tmp}/cc-statusline.out"
npx -y @dartchuk-s/cc-statusline@latest | tee "$OUT_FILE"
```

**b. Reader that strips ANSI and hides stale output:**

Create `~/.claude/cc-statusline-tmux.sh`:

```bash
#!/bin/bash
set -euo pipefail
FILE="${TMPDIR:-/tmp}/cc-statusline.out"
[[ -s $FILE ]] || exit 0
if [[ "$(find "$FILE" -mmin -1 2>/dev/null)" == "" ]]; then
  exit 0
fi
line=$(head -1 "$FILE")
printf '%s' "$line" | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g'
```

Make both executable:

```bash
chmod +x ~/.claude/cc-statusline-{wrapper,tmux}.sh
```

Wire the wrapper into `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/cc-statusline-wrapper.sh",
    "padding": 0,
    "refreshInterval": 10
  }
}
```

If you skip this step the center of the status bar will simply be empty — everything else still works.

### 7. Start (or reload) tmux

Fresh start:

```bash
tmux
```

Already running? Reload without killing sessions:

```
Ctrl-s r
```

The `r` binding does a hard reload — it clears leftover `status-format` slots so old multi-row layouts don't survive.

## Key bindings

### Prefix

- **`Ctrl-s`** — the prefix (default `Ctrl-b` is unbound)
- **`Ctrl-s r`** — reload config
- **`Ctrl-s I`** — TPM install plugins
- **`Ctrl-s Ctrl-s`** — resurrect save
- **`Ctrl-s Ctrl-r`** — resurrect restore

### Panes

- **`Ctrl-s |`** — split vertical (keeps cwd)
- **`Ctrl-s -`** — split horizontal (keeps cwd)
- **`Ctrl-h / j / k / l`** — hop panes (also traverses into nvim splits)

### Copy mode

- **`Ctrl-s [`** — enter copy mode
- **`v`** — start selection (charwise)
- **`V`** — start selection (linewise)
- **`y`** — copy to macOS clipboard (`pbcopy`)
- **Drag with mouse** — auto-select + copy on release

### Windows

- **`Ctrl-s c`** — new window
- **`Ctrl-s n / p`** — next / prev
- **`Ctrl-s 0-9`** — jump to window N

## Layout persistence

`tmux-continuum` auto-saves every 15 minutes; restoring is automatic when you `tmux` back in:

```bash
tmux kill-server && tmux    # safe — sessions/panes/cwds restore
```

Snapshots live at `~/.local/share/tmux/resurrect/` (or `~/.tmux/resurrect/`).

By default only "safe" processes (`vim`, `nvim`, `less`, `man`, `tail`) are auto-restarted. To also relaunch things like `claude` or a dev server on restore, add to `tmux.conf`:

```tmux
set -g @resurrect-processes 'claude "~python->python" "~node->node"'
```

## Uninstall

```bash
rm ~/.tmux.conf
rm -rf ~/.tmux/plugins
tmux kill-server
```
