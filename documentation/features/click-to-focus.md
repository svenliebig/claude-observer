# Click-to-Focus

Clicking a session entry in the dropdown menu focuses the corresponding tmux pane in Ghostty.

## How It Works

### Data Flow

1. The hook script captures the `TMUX_PANE` environment variable (e.g., `%0`, `%5`) when writing session state
2. The tmux pane ID is stored in the session JSON as `tmux_pane`
3. When the user clicks a session menu item, the Swift app:
   - Runs `tmux select-window -t <pane_id>` to make the window containing the pane active
   - Runs `tmux select-pane -t <pane_id>` to select the specific pane
   - Runs `tmux switch-client -t <pane_id>` to switch the most recently active tmux client to the session containing the pane (handles cross-session navigation)
   - Activates Ghostty via AppleScript to bring it to the foreground

### Requirements

- Claude Code must be running inside a tmux session
- Ghostty must be the terminal emulator
- If `TMUX_PANE` is not set (session not in tmux), the menu item is still shown but clicking does nothing

### Menu Item Behavior

- Session entries in the dropdown become clickable (enabled) when a `tmux_pane` is present
- Sessions without tmux pane info remain display-only (disabled)
