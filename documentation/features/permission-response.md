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
- **deny**: exit code 2 (stderr: "Denied via Claude Observer")
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
