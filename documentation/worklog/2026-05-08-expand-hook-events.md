# Expand Hook Events for Reliable Notifications

**Date:** 2026-05-08

**Task:** Update the hook system to cover all Claude Code lifecycle events and add matchers to ensure reliable notification delivery.

## Investigation

Compared the current hook setup (7 events, no matchers) against the full Claude Code hook API. Found:

1. **`PermissionRequest` was missing** — When Claude asks for tool permission, the session stayed "working" instead of transitioning to "needs_permission". The Swift app already supported this status but it was never triggered by the hook.
2. **No `matcher: "*"` on matcher-based events** — `PreToolUse`, `Notification` may not fire reliably without an explicit wildcard matcher.
3. **Missing activity events** — `PostToolUse`, `SubagentStart`, `SubagentStop`, `PreCompact` were not tracked, causing stale timestamps and missed state transitions.

## Changes

### `hooks/observer-hook.py`

Added 5 new event handlers:
- `PermissionRequest` → status `"needs_permission"` + Ping sound
- `PostToolUse` → status `"working"`, updates `last_activity`
- `SubagentStart` → status `"working"`, updates `last_activity`
- `SubagentStop` → updates `last_activity` (preserves current status)
- `PreCompact` → updates `last_activity` (preserves current status)

### `scripts/install.py`

- Restructured from flat event list to a dict so each event can specify its own entry structure
- Added `"matcher": "*"` to `PreToolUse`, `PostToolUse`, `Notification`, `PermissionRequest`
- Added `"timeout": 86400` to `PermissionRequest` hook
- Total events: 7 → 12

### Documentation

- Updated `architecture/03-context-and-scope.md` with full event list
- Added "Scenario 2b: Session Needs Permission" to `architecture/06-runtime-view.md`

## Decisions

- `SubagentStop` and `PreCompact` only update `last_activity` without changing status, since they don't represent a meaningful state transition.
- `PermissionRequest` uses the same Ping sound as `Notification` for consistency.
- Existing installations require `make uninstall && make install` to replace old hook entries (without matchers) with new ones.
