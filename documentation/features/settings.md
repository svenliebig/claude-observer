# Settings

Claude Observer supports user-configurable settings, persisted locally at `~/.claude-observer/settings.json`.

## Accessing Settings

Right-click the Dynamic Island widget to open the context menu, then select "Settings..." to open the settings window.

## Settings File

Settings are stored as JSON at `~/.claude-observer/settings.json`. Both the Swift app and the Python hook script read this file.

### Schema

```json
{
  "permission_sound": "Ping",
  "error_sound": "Basso"
}
```

### Sound Settings

| Key | Default | Description |
|-----|---------|-------------|
| `permission_sound` | `"Ping"` | Sound played when a session needs input or permission. Set to `""` to disable. |
| `error_sound` | `"Basso"` | Sound played on session error. Set to `""` to disable. |

Available sounds are the macOS system sounds found in `/System/Library/Sounds/` (e.g., Ping, Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Pop, Purr, Sosumi, Submarine, Tink).

## Architecture

- **Swift app** (`Sources/main.swift`): Reads and writes `settings.json`. Provides the settings window UI.
- **Python hook** (`hooks/observer-hook.py`): Reads `settings.json` to determine which sound to play (or skip sound if disabled).
