# Build System

Claude Observer uses a `Makefile` for build orchestration and Python scripts for installation logic.

## Makefile Targets

| Target | Command | Description |
|--------|---------|-------------|
| `build` | `make build` | Compiles the Swift app to `~/.claude-observer/bin/claude-observer` |
| `install` | `make install` | Runs `scripts/install.py` (compile + hook setup + settings config) |
| `uninstall` | `make uninstall` | Runs `scripts/uninstall.py` (remove hooks, binary, state) |
| `run` | `make run` | Builds and launches the app in floating Dynamic Island mode |
| `run-menubar` | `make run-menubar` | Builds and launches the app in menu bar mode (`--menubar`) |
| `stop` | `make stop` | Kills the running `claude-observer` process via `pkill` |
| `clean` | `make clean` | Removes the binary and all session JSON files |

## Compilation

The Swift app is a single-file compilation:

```bash
swiftc -O -o ~/.claude-observer/bin/claude-observer Sources/main.swift -framework Cocoa -framework Network
```

- `-O`: Optimized build
- `-framework Cocoa`: Links AppKit and Foundation
- `-framework Network`: Used by the local web dashboard server
- No Swift Package Manager or Xcode project needed

## Runtime Flags

The binary chooses its UI surface at startup based on CLI flags:

| Flag | Effect |
|------|--------|
| _(none)_ / `--floating` | Floating Dynamic Island panel at the top of the screen (default) |
| `--menubar` / `--statusbar` | Status item in the macOS menu bar with a click-down session panel |

The mode is parsed once at launch (`DisplayMode.from(arguments:)`) -- switching modes requires restarting the binary.

## Installation Process (`scripts/install.py`)

1. Creates `~/.claude-observer/{bin,hooks,sessions}` directories
2. Copies `hooks/observer-hook.py` to `~/.claude-observer/hooks/` and makes it executable
3. Compiles `Sources/main.swift` to `~/.claude-observer/bin/claude-observer`
4. Reads `~/.claude/settings.json` and registers the hook for all tracked events
5. Writes the updated settings back

### Hook Registration

The install script adds the observer hook to these Claude Code events in `~/.claude/settings.json`:

- `SessionStart`, `SessionEnd`
- `UserPromptSubmit`, `PreToolUse`
- `Stop`, `StopFailure`
- `Notification`

Each event entry follows this structure:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "python3 ~/.claude-observer/hooks/observer-hook.py"
    }
  ]
}
```

The installer checks for existing hooks containing `observer-hook.py` to avoid duplicates.

## Uninstallation Process (`scripts/uninstall.py`)

1. Kills any running `claude-observer` process
2. Removes all observer hook entries from `~/.claude/settings.json`
3. Deletes `~/.claude-observer/` and all its contents
