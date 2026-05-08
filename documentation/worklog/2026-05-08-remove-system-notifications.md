# Remove System Notifications

**Date:** 2026-05-08

**Task:** Remove macOS system notifications to eliminate double beep — the Dynamic Island is sufficient for visual alerts.

## Investigation

Two independent sound sources fired on attention-needed events:
1. Hook script (`observer-hook.py`): `afplay /System/Library/Sounds/Ping.aiff` on `Notification`/`PermissionRequest`
2. Swift app (`main.swift`): `osascript display notification ... sound name "Ping"` triggered from `sendNotification()` during polling

Both produced a Ping sound, resulting in a double beep.

## Changes

### Swift app (`Sources/main.swift`)
- Removed `notifiedSessions: Set<String>` property
- Removed notification tracking loop in `pollSessions()` (insert/remove/prune of `notifiedSessions`, call to `sendNotification`)
- Removed `sendNotification(session:)` method (the `osascript` call)

### Documentation
- `notifications.md` — rewritten: removed Desktop Notifications and Duplicate Prevention sections
- `overview.md` — removed Desktop Notifications feature row
- `03-context-and-scope.md` — removed macOS Notification Center interface, updated diagram
- `05-building-block-view.md` — removed `notifiedSessions` and `sendNotification`
- `06-runtime-view.md` — removed `osascript notification` from scenarios 2 and 2b
- `09-architecture-decisions.md` — replaced ADR-4 with Dynamic Island rationale
- `11-risks-and-technical-debt.md` — removed osascript tech debt item
- `stack.md` — removed `osascript` dependency
- `README.md` — updated wording to "Sound alert"
- `docs/index.html` — updated feature card and how-it-works step

## Decisions

- Keep the hook script's `afplay` sounds — they provide the single audio cue
- The Dynamic Island handles all visual alerting, making system notifications redundant
