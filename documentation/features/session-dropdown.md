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

## Status Labels and Colors

| Status | Label | Dot | Color |
|--------|-------|-----|-------|
| working | WORKING | filled green | Green |
| needs_input | WAITING FOR INPUT | filled red | Red (heavy weight) |
| needs_permission | NEEDS PERMISSION | filled orange | Orange |
| idle | idle | hollow gray | Gray |
| error | ERROR | filled pink | Pink |

## Sort Order

Sessions are sorted by their `started_at` timestamp in ascending order (oldest first).

## Menu Rebuilding

The entire menu is rebuilt on every poll cycle (every 2 seconds) and on every animation frame (every 0.5 seconds), ensuring the display stays current.
