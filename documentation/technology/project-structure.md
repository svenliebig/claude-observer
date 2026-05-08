# Project Structure

```
claude-observer/
|-- Sources/
|   +-- main.swift              # macOS status bar application (single file)
|-- hooks/
|   +-- observer-hook.py        # Claude Code hook script
|-- scripts/
|   |-- install.py              # Installation script
|   +-- uninstall.py            # Uninstallation script
|-- docs/
|   +-- index.html              # Project landing page (static HTML)
|-- documentation/              # Software documentation (this directory)
|   |-- features/               # Feature documentation
|   |-- technology/             # Technology stack documentation
|   +-- architecture/           # Arc42 architecture documentation
|-- Makefile                    # Build orchestration
+-- README.md                   # Project readme
```

## File Responsibilities

### `Sources/main.swift`
The complete macOS status bar application in a single Swift file. Contains:
- `CrabSession` - Codable model for session data
- `CrabRenderer` - Core Graphics drawing code for all crab states and animations
- `ClaudeObserverDelegate` - `NSApplicationDelegate` handling polling, display updates, menu construction, and notifications
- Entry point configuring `NSApplication` as an accessory app (no Dock icon)

### `hooks/observer-hook.py`
The hook script invoked by Claude Code on session lifecycle events. Reads event data from stdin as JSON, writes/updates/deletes session files in `~/.claude-observer/sessions/`.

### `scripts/install.py`
Automates the full installation: directory creation, file copying, Swift compilation, and Claude Code settings configuration.

### `scripts/uninstall.py`
Reverses installation: kills the running process, removes hook entries from settings, and deletes the `~/.claude-observer/` directory.

### `docs/index.html`
A self-contained landing page with animated SVG crabs, feature descriptions, and installation instructions. Uses no external JavaScript; CSS animations only.

## Runtime File Layout

After installation, the following structure exists at `~/.claude-observer/`:

```
~/.claude-observer/
|-- bin/
|   +-- claude-observer         # Compiled Swift binary
|-- hooks/
|   +-- observer-hook.py        # Hook script (copied from repo)
+-- sessions/
    |-- {session-id-1}.json     # Active session state files
    +-- {session-id-2}.json
```
