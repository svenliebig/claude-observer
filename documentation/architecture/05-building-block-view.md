# 5. Building Block View

## Level 1: System Overview

```
+---------------------------------------------------------------+
|                        Claude Observer                         |
|                                                                |
|  +-------------------------+    +---------------------------+  |
|  |    Hook Script          |    |    Status Bar App         |  |
|  |    (Python)             |    |    (Swift)                |  |
|  |                         |    |                           |  |
|  |  observer-hook.py       |    |  main.swift               |  |
|  +------------+------------+    +-------------+-------------+  |
|               |                               |                |
|               v                               |                |
|  +---------------------------+                |                |
|  | ~/.claude-observer/       |<---------------+                |
|  | sessions/{id}.json        |   (reads every 2s)             |
|  +---------------------------+                                 |
+---------------------------------------------------------------+
```

## Level 2: Status Bar App Components

The `main.swift` file contains the following logical components:

### CrabSession (Data Model)

```
struct CrabSession: Codable
```

- Represents a single Claude Code session
- Fields: `id`, `name`, `cwd`, `status`, `pid`, `startedAt`, `lastActivity`, `notificationType`
- Maps between JSON snake_case keys and Swift camelCase properties via `CodingKeys`

### CrabRenderer (Rendering)

```
class CrabRenderer
  +-- createImage(size, frame, state) -> NSImage
  +-- drawCrab(ctx, w, h, frame, state)       [private]
  +-- color(r, g, b, a) -> CGColor            [private]
```

- Pure rendering component with no state
- Produces `NSImage` instances for any combination of size, animation frame, and crab state
- All drawing is done via `CGContext` operations: ellipses, lines, arcs, paths, text

### ClaudeObserverDelegate (Application Controller)

```
class ClaudeObserverDelegate: NSObject, NSApplicationDelegate
  State:
    - statusItem: NSStatusItem
    - menu: NSMenu
    - sessions: [String: CrabSession]
    - notifiedSessions: Set<String>
    - animFrame: Int
    - animTimer: Timer
    - pollTimer: Timer

  Methods:
    - applicationDidFinishLaunching()    Setup and start timers
    - isDuplicate() -> Bool              Prevent multiple instances
    - pollSessions()                     Read session files, cleanup stale, trigger notifications
    - updateDisplay()                    Set status bar icon and title
    - rebuildMenu()                      Construct dropdown menu items
    - addSessionItems(session)           Render a single session entry
    - stateFor(status) -> CrabState      Map status string to enum
    - sendNotification(session)          Send macOS notification via osascript
```

### Helper Functions

- `abbreviatePath(_:)` - Replaces the home directory prefix with `~`

## Level 2: Hook Script Components

The `observer-hook.py` script is linear (no classes):

1. **Input parsing** - Reads JSON from stdin, extracts `session_id`, `cwd`, `hook_event_name`, `notification_type`
2. **Name derivation** - Computes deterministic crab name from session ID via MD5
3. **File operations** - `read_session()`, `write_session()`, `ensure_session()` for managing JSON files
4. **Event handling** - A series of `if/elif` blocks mapping each event to the appropriate state update
