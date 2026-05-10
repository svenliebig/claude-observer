# Question Display Special Case

**Date:** 2026-05-10
**Task:** Implement a special case for the question type when Claude asks a question, instead of showing the same Allow/Deny/Always buttons as permission requests. Options should be clickable and a custom text input should be available.

## Investigation

- When Claude uses `AskUserQuestion`, it fires a `PermissionRequest` hook event with `tool_name: "AskUserQuestion"`
- The hook and widget treated this identically to tool permission requests, showing Yes/No/Allow all buttons
- These buttons are semantically wrong — a question needs the user to pick an option or type a custom answer

## Changes

### `hooks/observer-hook.py`
- Added `subprocess` import
- Fixed `summarize_tool_input` for AskUserQuestion — extracts question from `tool_input.questions[0].question`
- Added `tool_options` extraction — stores option labels from `questions[0].options` in the permission_request
- Added tmux answer automation: when `option_index` or `custom_answer` is in the response, spawns a background process that types the answer into the tmux pane via `tmux send-keys` after a 1.5s delay

### `Sources/main.swift`
- `PermissionRequestInfo`: Added `toolOptions: [String]?` field
- `sessionStatusInfo`: Shows "QUESTION" (yellow) instead of "PERMISSION" (orange) for AskUserQuestion
- `questionDisplayLines` / `questionRowHeight`: Separate layout methods for question rows
- Drawing: Options rendered as full-width clickable blue buttons, stacked vertically, with "Other..." button at the bottom
- Click handler: Option clicks send `allow` + `option_index`; "Other..." triggers a text input dialog
- `showQuestionInputDialog`: NSAlert with text field for custom answers
- `onPermissionResponse` callback extended to `(CrabSession, String, [String: Any])` to carry extra fields
- `respondToPermission` extended to write extra fields (option_index, custom_answer) to the response file
- `WebDashboardServer.onPermissionResponse` updated to pass extra fields through

### `web/index.html`
- Added `.card.question` CSS (yellow border), `.question-actions`, `.question-label`, `.btn-other` styles
- `buildCard`: Detects AskUserQuestion, renders "Question" status label, question text, and clickable option buttons + "Other..." button
- `handleQuestionOption`: Sends `allow` + `option_index`
- `handleQuestionCustom`: Shows browser `prompt()` dialog, sends `allow` + `custom_answer`
- `handlePermission`: Extended to accept optional `extra` fields

### `tests/test_hook.py` (new)
- Unit tests for `summarize_tool_input` covering AskUserQuestion and other tool types

## Decisions

- Options are clickable buttons that auto-type the answer into the tmux terminal via background `tmux send-keys`
- "Other..." opens a text input dialog (NSAlert on native, browser prompt on web), then types the custom answer into tmux
- Yellow color scheme distinguishes questions from permission requests (blue/orange)
- 1.5s delay before sending keys to allow Claude Code to display the question prompt
