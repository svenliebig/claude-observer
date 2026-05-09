# Terminal Detection & Focus + Widget Badges

**Date:** 2026-05-09
**Task:** Make it possible to click non-tmux sessions (Ghostty, Terminal.app) to jump to the application, widen the widget, and add terminal badge indicators.

## Investigation

- Traced process trees for Claude sessions in different terminals:
  - Terminal.app: `claude → zsh → login → Terminal.app`
  - Ghostty (no tmux): `claude → zsh → login → Ghostty.app`
  - tmux: `claude → zsh → tmux` (server ppid=1, can't see hosting terminal)
- Confirmed `ps -p PID -o comm=` reliably shows full path including app bundle name
- Existing click-to-focus only worked for sessions with `tmux_pane` set

## Changes

### Hook (`hooks/observer-hook.py`)
- Added `detect_terminal_app()`: walks process tree from `os.getppid()` upward, matches basename against known terminals (Ghostty, Terminal, iTerm2, WezTerm, Alacritty, kitty)
- Added `terminal_app` field to session JSON in `SessionStart` and `ensure_session()`
- Backfills on existing sessions when previously null

### Swift App (`Sources/main.swift`)
- Added `terminalApp` field to `CrabSession` model
- Added computed `isClickable` (has tmux or terminal app) and `badgeLabel` (short labels: tmux, ghostty, term, iterm, etc.)
- Widened widget: compact 240→270, expanded 400→440
- Hover highlight now works for all clickable sessions
- Terminal badge drawn as rounded-rect pill after crab name
- Non-tmux click: activates terminal app via AppleScript (`tell application "X" to activate`)
- Tmux click: now activates detected terminal app instead of hardcoded Ghostty
- Extracted shared `activateApp()` helper

## Decisions

- tmux sessions show "tmux" badge (can't detect hosting terminal from process tree since tmux server is detached)
- tmux focus falls back to Ghostty if no terminal_app detected (matches user's primary setup)
- Badge labels kept very short: "term" for Terminal.app, "iterm" for iTerm2, etc.
