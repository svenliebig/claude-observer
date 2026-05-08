# 7. Deployment View

## Deployment Diagram

```
+-------------------------------------------------------+
|                   macOS Machine                        |
|                                                        |
|  +--------------------------------------------------+  |
|  | User Home (~/)                                    |  |
|  |                                                   |  |
|  |  ~/.claude-observer/                              |  |
|  |  |-- bin/claude-observer    (compiled binary)     |  |
|  |  |-- hooks/observer-hook.py (hook script)         |  |
|  |  +-- sessions/              (runtime state)       |  |
|  |      |-- {session-1}.json                         |  |
|  |      +-- {session-2}.json                         |  |
|  |                                                   |  |
|  |  ~/.claude/settings.json    (hook registration)   |  |
|  +--------------------------------------------------+  |
|                                                        |
|  +--------------------------------------------------+  |
|  | Running Processes                                 |  |
|  |                                                   |  |
|  |  claude-observer (status bar app, background)     |  |
|  |  claude (Claude Code session 1)                   |  |
|  |    +-- python3 observer-hook.py (invoked per evt) |  |
|  |  claude (Claude Code session 2)                   |  |
|  |    +-- python3 observer-hook.py (invoked per evt) |  |
|  +--------------------------------------------------+  |
+-------------------------------------------------------+
```

## Installation Artifacts

| Path | Type | Installed By |
|------|------|-------------|
| `~/.claude-observer/bin/claude-observer` | Compiled Swift binary | `scripts/install.py` |
| `~/.claude-observer/hooks/observer-hook.py` | Python script (copied) | `scripts/install.py` |
| `~/.claude-observer/sessions/` | Directory (created) | `scripts/install.py` |
| `~/.claude/settings.json` | Modified (hooks added) | `scripts/install.py` |

## Process Model

- **Status bar app**: Long-running background process. Starts manually or via Login Items. Single instance enforced via `pgrep`.
- **Hook script**: Short-lived process. Spawned by Claude Code for each hook event. Reads stdin, writes a file, exits. Multiple instances may run concurrently (one per Claude Code session).

## Auto-Start

The binary can be added to macOS Login Items (`System Settings > General > Login Items`) for automatic startup at login. This is a manual step documented in the README.
