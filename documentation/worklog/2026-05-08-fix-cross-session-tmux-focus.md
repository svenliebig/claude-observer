# Fix cross-session tmux focus

**Date:** 2026-05-08

**Task:** The jump to tmux works when the user is currently in the same session as the window, but not when the Claude instance is running in another session. Find out why and fix.

## Investigation

The `focusTmuxPane` method in `Sources/main.swift` used `tmux select-window` and `tmux select-pane` to navigate to a Claude session's pane. These commands modify the target session's internal state (active window/pane) on the tmux server, but do not switch the user's tmux client to that session. When the user's terminal is attached to a different tmux session, the changes are invisible.

## Changes

- **`Sources/main.swift`**: Added `tmux switch-client -t <paneId>` after `select-window` and `select-pane`. This switches the most recently active tmux client to the session containing the target pane.
- **`documentation/features/click-to-focus.md`**: Updated data flow to document the `switch-client` step.

## Decisions

- `switch-client` is called after `select-window`/`select-pane` so the correct window and pane are already selected when the client switches, giving the user an immediate view of the right pane.
- No `-c` flag is passed to `switch-client`, so it defaults to the most recently active client, which is the expected behavior for a menu bar app triggering focus.
