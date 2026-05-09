# Fix Permission Button Labels and Behavior

**Date:** 2026-05-09

**Task:** Fix permission widget buttons to match the Claude Code CLI options. The "Always" button was misleading and the `permissionRule` mechanism wasn't working. Buttons should be "Yes", "Allow all {category}", "No" — matching the terminal's "Yes", "Yes, allow all edits during this session", "No".

## Investigation

- The widget had three buttons: "Allow" (green), "Deny" (red), "Always" (blue)
- The CLI shows: "Yes", "Yes, allow all edits during this session (shift+tab)", "No"
- The "Always" button sent `always_allow` with a `permissionRule` that was supposed to create a permanent rule in settings.local.json, but it wasn't working
- The CLI's "allow all" option is session-scoped, not permanent

## Changes

### `hooks/observer-hook.py`
- Added `TOOL_CATEGORIES` mapping (Write/Edit → "edits", Bash → "bash", etc.)
- Added session-level auto-allow: stores allowed categories in `session["allowed_categories"]` and auto-approves future requests for those categories
- Removed broken `permissionRule` output — allow-all is now session-only
- Passes `tool_category` in permission data so the Swift UI can display it

### `Sources/main.swift`
- Added `toolCategory` optional field to `PermissionRequestInfo`
- Changed `buttonSpecs` from static constant to dynamic method that generates labels based on the tool category
- Button labels now: "Yes" (green), "No" (red), "Allow all {category}" (blue) with dynamically computed width

## Decisions

- Tool category mapping is defined in Python (single source of truth) and passed to Swift via the session data
- Session-level allow is implemented in the hook script (stored in session JSON), not via Claude Code's `permissionRule` API
- The `allowed_categories` field groups tools by category (e.g., both Write and Edit map to "edits"), matching CLI behavior
