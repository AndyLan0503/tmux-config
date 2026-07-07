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

### 6. Optional: agent-harness statusline

> The tmux config is agent-harness agnostic. If you skip this whole section, the center of the status bar is blank and no errors are printed — every other feature (splits, copy mode, resurrect, vim-tmux-navigator, etc.) works untouched.

#### How it works

Every 5 seconds, tmux runs `scripts/tmux-agent.sh`, which scans `$TMPDIR/agent-cache-*.out` for the freshest file written in the last 60s. That file's line 1 (ANSI stripped) becomes the centered status.

Each agent has its own writer script that populates its cache file. Whichever agent last wrote wins the center. If no agent has written recently, the center is blank.

#### Claude Code (push-driven)

Claude Code has a native `statusLine` hook. Point it at `scripts/claude-statusline.sh`, which wraps [`cc-statusline`](https://www.npmjs.com/package/@dartchuk-s/cc-statusline) and tees output to the cache.

Edit `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/repos/tmux-config/scripts/claude-statusline.sh",
    "padding": 0,
    "refreshInterval": 10
  }
}
```

You'll see `Model | Ctx | 5h | 7d | $cost · duration` in the tmux bar on Claude's next render. `npx` fetches `cc-statusline` the first time; nothing else to install.

#### Codex CLI (scaffold, poll-driven)

Codex doesn't yet expose a native statusLine hook, so `scripts/codex-statusline.sh` starts as a **scaffold**: it detects a running `codex` process and writes `"Codex: active"` to its cache. Two ways to run it:

**a. Manual / cron.** Add to your crontab (or a shell one-liner background loop):

```
* * * * * ~/repos/tmux-config/scripts/codex-statusline.sh
```

**b. Codex hook (once Codex supports it).** Enable in `~/.codex/config.toml`:

```toml
[features]
hooks = true
```

Then wire whichever hook Codex ships to point at the script.

The script has explicit TODO comments for filling in real session data (model, context %, quota) once Codex exposes it — for now it's a bare "active" indicator so you can verify the plumbing works.

#### Adding more agents

Drop a `scripts/<agent>-statusline.sh` that writes to `$TMPDIR/agent-cache-<agent>.out`. `tmux-agent.sh` picks it up automatically — no tmux.conf changes needed.

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
