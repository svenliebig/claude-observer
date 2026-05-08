# 8. Crosscutting Concepts

## File-based Communication

All communication between the hook script and the status bar app goes through JSON files on the filesystem. This is the central architectural pattern:

- **Write side** (hook): Atomic writes via temp file + `os.replace()`
- **Read side** (app): Tolerant JSON parsing with `try?` - silently skips malformed files
- **Cleanup**: Both sides participate - hooks delete on `SessionEnd`, app cleans stale sessions

## Error Handling Strategy

The system follows a "keep running, skip errors" philosophy:

- **Hook script**: Wraps stdin parsing in `try/except` and exits silently on failure. This ensures a malformed event never blocks Claude Code.
- **Status bar app**: All file operations use `try?` or optional chaining. A single corrupt session file is skipped without affecting other sessions.
- **No crash propagation**: Errors in one component (hook or app) never affect the other.

## Animation System

Animation is tick-based rather than time-based:

- A global `animFrame` counter increments every 0.5 seconds (2 FPS)
- All animated properties are derived from `animFrame` using modulo arithmetic
- The entire status bar icon is redrawn on every tick (no incremental updates)
- Each menu item's crab icon is also redrawn per tick

## Duplicate Instance Prevention

On launch, the app runs `pgrep -x claude-observer` and checks if any returned PID differs from its own. If so, it terminates immediately. This prevents confusion from multiple status bar items.

## Path Display

User-facing paths are shortened by replacing the home directory prefix with `~` via the `abbreviatePath()` helper, applied in both the menu detail row and notification body.

## Deterministic Naming

Both the Python hook and the Swift app contain the same list of 35 crab names. Name assignment uses MD5 hashing of the session ID, ensuring the same session always maps to the same name regardless of which component derives it.
