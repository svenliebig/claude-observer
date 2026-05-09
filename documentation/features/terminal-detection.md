# Terminal Detection & Focus

Claude Observer detects which terminal application each Claude Code session is running in and enables click-to-focus for all terminal types.

## Detection

The hook script (`observer-hook.py`) detects the terminal app by walking up the process tree from the Claude Code process to find a known terminal application. It stores the result as `terminal_app` in the session JSON.

Known terminal apps: `Ghostty`, `Terminal`, `iTerm2`, `WezTerm`, `Alacritty`, `kitty`.

## Focus Behavior

When a session row is clicked in the expanded widget:

| Scenario | Behavior |
|----------|----------|
| Has `tmux_pane` | Select tmux window/pane, then activate the terminal app |
| No tmux, has `terminal_app` | Activate the terminal app via `NSWorkspace` using the stored PID to focus the correct window |
| Neither | No action (row not clickable) |

## Widget Badge

Each session row displays a small badge indicating the terminal environment:
- `tmux` - running inside tmux
- `ghostty` / `term` / `iterm` / etc. - the detected terminal app (shown only when no tmux)
