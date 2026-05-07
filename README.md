# Claude Observer

A macOS status bar app that shows your running Claude Code sessions as cute little crabs.

Each Claude instance gets a unique crab name (Pinchy, Snippy, Clawdia...) and the status bar shows their current state with animated crabs.

## Features

- Animated crab in the status bar showing aggregate session state
- Dropdown menu listing each Claude session with its crab name
- Desktop notification with "ding" when a Claude needs your input
- Auto-cleanup of stale sessions
- Per-session status: working, idle, needs input, needs permission, error

## Crab States

| State | Crab Look | Meaning |
|-------|-----------|---------|
| Working | Orange crab, legs wiggling | Claude is processing |
| Idle | Gray crab with "z" | Waiting for your next prompt |
| Needs Input | Red bouncing crab with "!" | Claude needs your attention |
| Error | Pink crab | API error occurred |

## Install

```bash
make install
```

This will:
1. Compile the Swift status bar app
2. Install the hook script to `~/.claude-observer/hooks/`
3. Add hooks to `~/.claude/settings.json` for session tracking

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
The status bar app polls this directory every 2 seconds and updates the display.

### Tracked Events

| Hook Event | Action |
|------------|--------|
| `SessionStart` | Creates session file |
| `UserPromptSubmit` | Marks session as "working" |
| `Stop` | Marks session as "idle" |
| `StopFailure` | Marks session as "error" |
| `Notification` | Marks as "needs input" + plays ding |
| `SessionEnd` | Removes session file |

## Requirements

- macOS 12+
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3 (ships with macOS / Xcode CLT)
