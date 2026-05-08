# Session Lifecycle

Claude Observer tracks session state through Claude Code hook events. Each event updates a JSON file on disk that the status bar app reads.

## Hook Events

| Event | Action | Resulting Status |
|-------|--------|-----------------|
| `SessionStart` | Creates a new session JSON file | `working` |
| `UserPromptSubmit` | Updates session status and `last_activity` | `working` |
| `PreToolUse` | Updates session status and `last_activity` | `working` |
| `Stop` | Updates session status | `idle` |
| `StopFailure` | Updates session status, plays error sound | `error` |
| `Notification` | Updates session status, plays ping sound | `needs_input` |
| `SessionEnd` | Deletes the session JSON file | (removed) |

## Session File Format

Each session is stored as `~/.claude-observer/sessions/{session_id}.json`:

```json
{
  "id": "session-uuid",
  "name": "Pinchy",
  "cwd": "/Users/user/workspace/my-project",
  "status": "working",
  "pid": 12345,
  "started_at": "2025-01-15T10:30:00Z",
  "last_activity": "2025-01-15T10:31:42Z",
  "notification_type": null
}
```

## Atomic Writes

The hook script writes session files atomically: it writes to a `.tmp` file first, then uses `os.replace()` to atomically move it into place. This prevents the Swift app from reading a partially-written file.

## Session Recovery

If a hook event fires for a session that doesn't have an existing file (e.g., the file was manually deleted), the `ensure_session()` function creates a new session record on the fly with the current event data.

## Stale Session Cleanup

The Swift app performs stale session detection on every poll cycle:

1. For each session file, check if the stored PID is still alive (`kill(pid, 0)`)
2. If the process is dead (`errno == ESRCH`) and `last_activity` is older than 5 minutes, delete the session file
3. This handles cases where Claude Code crashes without firing a `SessionEnd` event
