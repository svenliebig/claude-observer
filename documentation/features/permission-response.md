# Permission Response

## Overview

When a Claude Code instance requests permission for a tool use (e.g., running a bash command, editing a file), the observer widget shows the permission details and allows the user to respond directly from the Dynamic Island UI.

## Mechanism

### Data Flow

1. Claude Code fires `PermissionRequest` hook event with `tool_name` and `tool_input`
2. Hook script writes permission details to session file and polls for a response file
3. Swift app sees `needs_permission` status with `permission_request` data
4. Widget shows tool name + summary and action buttons in an expanded permission row
5. User clicks Allow / Deny / Always Allow
6. Swift app writes `~/.claude-observer/sessions/{session_id}.response.json`
7. Hook script reads response, outputs decision JSON on stdout, deletes response file
8. Claude Code processes the decision

### Response File

Location: `~/.claude-observer/sessions/{session_id}.response.json`

```json
{"decision": "allow"}
```

Possible decisions: `"allow"`, `"deny"`, `"always_allow"`

### Hook Output

The hook translates the response into Claude Code's expected format:

- **allow**: `{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow"}}}`
- **deny**: `{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "deny"}}}`
- **always_allow**: `{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow", "permissionRule": "<ToolName>"}}}`

### Timeout

If no response is received within 120 seconds, the hook exits with code 0 and no stdout output. Claude Code falls through to its normal interactive permission prompt in the terminal.

## UI

### Permission Row (expanded view)

When a session has `needs_permission` status, the session row gains an additional line showing:

- Tool name and a concise summary of the tool input
- Three action buttons: Allow (green), Deny (red), Always Allow (blue)

Row height increases from 52px to ~85px for permission rows.

### Tool Input Summary

| Tool | Summary |
|------|---------|
| Bash | Command text (truncated) |
| Edit, Write, Read | File path |
| Glob, Grep | Pattern |
| WebFetch | URL |
| WebSearch | Query |
| MCP tools | Tool name |
| Other | Tool name |

## Code Preview

When a `Write` tool permission is requested, the widget shows a scrollable code preview area above the action buttons. This gives the user visibility into what Claude wants to write without switching to the terminal.

### Layout

```
[Session header: crab icon, name, status, time]
[Tool header: "Write: ~/path/to/file"]
[Code preview: scrollable, up to 15 visible lines]
[Allow] [Deny] [Always]
```

### Features

- **Line numbers**: Gray gutter with right-aligned line numbers
- **Syntax highlighting**: Basic token-based coloring by file extension (JSON, generic fallback)
- **Scrolling**: Mouse wheel scrolls through content when it exceeds 15 lines
- **Scroll indicator**: Thin bar on the right edge shows position in long files
- **Content limit**: Hook sends first 100 lines of file content to keep session files small

### Data Flow

1. Hook receives `PermissionRequest` with `tool_input` containing `content` field
2. Hook writes `tool_content` (first 100 lines) into `permission_request` in session JSON
3. Swift app detects `tool_content` and renders the code preview area
4. File extension is derived from `tool_summary` (the file path) for syntax highlighting

### Syntax Highlighting

| Extension | Style |
|-----------|-------|
| `.json` | Keys (cyan), strings (green), numbers (blue), booleans/null (purple) |
| Other | Strings (green), numbers (blue), comments (gray) |
