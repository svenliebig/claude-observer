# Claude Observer

A macOS Dynamic Island-style floating panel that shows your running Claude Code sessions as cute little crabs.

Each Claude instance gets a unique crab name (Pinchy, Snippy, Clawdia...) and the panel shows their current state with animated crabs and a color-coded glow.

## Features

- **Dynamic Island UI** — floating panel at the top center of your screen, expands on click to show all sessions
- **Animated crabs** — each session gets a pixel-art crab with state-dependent animations
- **Permission management** — approve, deny, or "Always Allow" tool permissions directly from the panel, with code preview for file writes
- **Terminal detection** — auto-detects Ghostty, iTerm2, Terminal, WezTerm, Alacritty, and kitty
- **Click to focus** — click a session to switch to its terminal window (tmux pane selection supported)
- **Sound alerts** — configurable sounds for permission requests and errors
- **Auto-cleanup** — removes stale sessions (dead process + inactive for 5 minutes)
- **Settings** — right-click the panel to configure notification sounds

## Crab States

| State | Crab | Glow | Meaning |
|-------|------|------|---------|
| Working | Orange, wiggling legs, sparkles | Green | Claude is processing |
| Idle | Gray, sleeping eyes, "zz" | None | Waiting for your next prompt |
| Needs Input | Red, bouncing, "!" badge | Pulsing orange | Claude finished and needs your attention |
| Needs Permission | Red, bouncing, "!" badge + action buttons | Pulsing orange | A tool needs your approval |
| Error | Pink, "!" badge | Pulsing pink | API error occurred |

## Permission Handling

When Claude requests permission to use a tool, the panel expands to show:

- The tool name and a summary (file path, command, URL, etc.)
- A scrollable code preview with syntax highlighting for file write operations
- Three action buttons: **Yes**, **No**, **Allow all [category]**

"Allow all" grants the category (edits, bash, file reads, file searches, web fetches, web searches) for the rest of that session.

If you handle the permission in your terminal instead, the panel detects it and clears automatically. Unhandled requests time out after 120 seconds.

## Install

```bash
make install
```

This will:
1. Create `~/.claude-observer/` with `bin/`, `hooks/`, and `sessions/` directories
2. Compile the Swift app to `~/.claude-observer/bin/claude-observer`
3. Copy the hook script to `~/.claude-observer/hooks/`
4. Register hooks in `~/.claude/settings.json`

## Run

```bash
make run
```

Or directly:
```bash
~/.claude-observer/bin/claude-observer &
```

To auto-start on login, add the binary to **System Settings > General > Login Items**.

## Stop

```bash
make stop
```

## Uninstall

```bash
make uninstall
```

## How It Works

Claude Code hooks write session state to `~/.claude-observer/sessions/` as JSON files.
The app polls this directory every 2 seconds and updates the display.

### Tracked Events

| Hook Event | Action |
|------------|--------|
| `SessionStart` | Creates session file |
| `UserPromptSubmit` | Marks session as "working" |
| `PreToolUse` | Marks session as "working" |
| `PostToolUse` | Marks session as "working" |
| `SubagentStart` | Marks session as "working" |
| `SubagentStop` | Updates last activity |
| `PreCompact` | Updates last activity |
| `Stop` | Marks session as "idle" |
| `StopFailure` | Marks session as "error", plays sound |
| `Notification` | Marks as "needs_input", plays sound |
| `PermissionRequest` | Shows permission UI, waits for response |
| `SessionEnd` | Removes session file |

## Supported Terminals

| Terminal | Badge |
|----------|-------|
| Ghostty | `ghostty` |
| iTerm2 | `iterm` |
| Terminal.app | `term` |
| WezTerm | `wez` |
| Alacritty | `alac` |
| kitty | `kitty` |
| tmux | `tmux` |

## Requirements

- macOS 12+
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3 (ships with macOS / Xcode CLT)
