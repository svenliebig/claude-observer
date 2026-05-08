# Session Dropdown Menu

Clicking the status bar crab opens a dropdown menu listing all active Claude Code sessions.

## Menu Structure

```
Claude Observer          (header, bold)
─────────────────────────
[crab] * Pinchy  my-api  WORKING
       ~/workspace/projects/my-api
[crab] * Clawdia  frontend  WAITING FOR INPUT
       ~/workspace/projects/frontend
[crab] o Scuttles  infra  idle
       ~/workspace/projects/infra
─────────────────────────
Quit Claude Observer  (cmd+Q)
```

## Session Item Details

Each session entry consists of two rows:

**Primary row:**
- A 16x16 animated crab icon matching the session's state
- A colored status dot (filled circle for active states, hollow for idle)
- The crab name in semibold
- The last path component of the working directory
- A status label in the session's state color

**Detail row:**
- The full working directory path with `~` substituted for the home directory
- Displayed in monospaced font at smaller size

## Custom View Rendering

Each session entry uses a custom `NSView` (`SessionMenuItemView`) instead of standard `NSMenuItem` attributed titles. This provides:

- **Custom hover highlight**: A subtle rounded rectangle instead of the system's blue highlight, ensuring text remains readable on hover.
- **System-adaptive colors**: Uses `NSColor.labelColor`, `.secondaryLabelColor`, and `.tertiaryLabelColor` for text, which adapt to dark/light mode and always maintain contrast.
- **Click handling**: The view handles mouse events directly, closing the menu and triggering tmux focus on click.

## Status Labels and Colors

Status colors use macOS system dynamic colors for proper contrast in all states:

| Status | Label | Dot Color | Label Color |
|--------|-------|-----------|-------------|
| working | WORKING | `systemGreen` | `systemGreen` |
| needs_input | WAITING FOR INPUT | `systemRed` | `systemOrange` |
| needs_permission | NEEDS PERMISSION | `systemOrange` | `systemOrange` |
| idle | idle | `tertiaryLabelColor` | `tertiaryLabelColor` |
| error | ERROR | `systemPink` | `systemPink` |

## Hover Behavior

When the mouse hovers over a session entry:
- A subtle rounded rectangle highlight is drawn (semi-transparent blue tint, 6px corner radius)
- All text colors remain fully readable against the highlight
- The cursor indicates clickability for sessions with tmux panes

## Sort Order

Sessions are sorted by their `started_at` timestamp in ascending order (oldest first).

## Menu Rebuilding

The entire menu is rebuilt on every poll cycle (every 2 seconds) and on every animation frame (every 0.5 seconds), ensuring the display stays current.
