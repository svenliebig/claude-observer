# Notifications

Claude Observer sends desktop notifications and plays sounds to alert the user when a session requires attention.

## Desktop Notifications

When a session transitions to `needs_input` or `needs_permission`, a native macOS notification is sent using AppleScript (`osascript`):

- **Title:** `"{CrabName} needs your attention!"`
- **Body:** The last path component of the session's working directory
- **Sound:** `Ping` (system sound)

Notifications are sent only once per attention-requiring state. When the session transitions back to `working` (e.g., after user submits a prompt), the notification tracking is reset, allowing a new notification on the next attention state.

## Sound Alerts

Two distinct sounds are used:

| Event | Sound | Triggered By |
|-------|-------|-------------|
| Session needs input | `Ping.aiff` | Hook script (`afplay`) when transitioning from `working` to `needs_input` |
| Session error | `Basso.aiff` | Hook script (`afplay`) on `StopFailure` event |

The Ping sound is played by the hook script only when the session was previously in a `working` state, preventing duplicate sounds on repeated notification events.

## Duplicate Prevention

The Swift app maintains a `notifiedSessions` set tracking which session IDs have already triggered a notification. A session ID is:
- Added when a notification is sent
- Removed when the session returns to `working`
- Pruned when the session no longer exists
