# Permission Response from Widget

**Date:** 2026-05-08

## Task

Allow users to see which permission a Claude instance is asking for and respond (Allow, Deny, Always Allow) directly from the Dynamic Island widget.

## Investigation

- The `PermissionRequest` hook event provides `tool_name` and `tool_input` on stdin
- Hooks can respond via stdout JSON (`behavior: allow/deny`) or exit code 2 (deny)
- The `permissionRule` field enables permanent "always allow" for a tool type
- Existing architecture uses file-based IPC (session JSON files polled every 2s)

## Changes

### `hooks/observer-hook.py`
- Added `summarize_tool_input()` to create human-readable summaries from tool input
- Rewrote `PermissionRequest` handler to:
  - Write `permission_request` (tool_name, tool_summary) to session file
  - Poll for `{session_id}.response.json` every 0.5s (120s timeout)
  - On response: output decision JSON to stdout, clear permission data
  - On timeout: clear permission data, exit 0 (falls through to Claude's terminal prompt)
- Added response file cleanup on `SessionEnd`

### `Sources/main.swift`
- Added `PermissionRequestInfo` Codable struct
- Added `permissionRequest` field to `CrabSession`
- Permission rows render at 85px (vs 52px standard) with:
  - Tool summary line (e.g., "Bash: npm install")
  - Three action buttons: Allow (green), Deny (red), Always (blue)
- Added `respondToPermission()` that writes response file with atomic rename
- Immediate local state update on button click for instant UI feedback
- Variable row height support in drawing, hit testing, and frame calculations

## Decisions

- **File-based response**: response files (`{id}.response.json`) extend the existing file-based IPC pattern
- **120s timeout**: if user doesn't respond, hook exits and Claude shows its normal terminal prompt
- **"Always" uses tool name as permission rule**: matches Claude Code's built-in always-allow behavior (e.g., `Bash` allows all bash commands)
- **Immediate local feedback**: Swift app updates in-memory session state instantly on button click rather than waiting for next poll cycle
