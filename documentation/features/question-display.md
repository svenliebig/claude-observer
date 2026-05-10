# Question Display

## Overview

When Claude asks the user a question via `AskUserQuestion` tool, the observer widget shows it differently from a permission request. Instead of Allow/Deny/Always buttons, it shows the question text and an "Open Terminal" button to direct the user to the terminal where they can type their answer.

## Mechanism

### How It Arrives

Claude Code fires a `PermissionRequest` hook event for `AskUserQuestion` just like any other tool. The hook and widget detect `tool_name == "AskUserQuestion"` and treat it as a special case.

### Data Flow

1. Claude uses `AskUserQuestion` tool → Claude Code fires `PermissionRequest` with `tool_name: "AskUserQuestion"`
2. Hook writes session with `needs_permission` status and `permission_request` containing question text
3. Widget detects `tool_name == "AskUserQuestion"` and renders question-specific UI
4. User clicks "Open Terminal" → widget sends `allow` decision and focuses the terminal
5. Hook receives `allow`, Claude proceeds to show the question in the terminal

### Hook Summary

For `AskUserQuestion`, the `tool_input` contains a `question` field. The hook extracts this as the `tool_summary`.

## UI

### Native Widget (Swift)

- Status label: "QUESTION" (yellow) instead of "PERMISSION" (orange)
- Display: Shows the question text (multi-line, wrapped)
- Button: Single "Open Terminal" button (system blue) — sends `allow` and focuses terminal
- No "Deny" or "Always Allow" buttons

### Web Dashboard

- Card style: Uses a distinct color (yellow border) to distinguish from permission cards (blue border)
- Shows the question text
- Single "Open Terminal" button instead of Allow/Deny/Always grid
