# Dynamic Island

The Dynamic Island is the primary UI surface of Claude Observer. It replaces the previous status bar icon + dropdown menu with a floating overlay panel near the top of the screen, inspired by Apple's iOS Dynamic Island concept.

## Concept

A dark, pill-shaped floating panel sits centered at the top of the screen (near the macOS notch on supported hardware). It morphs between compact and expanded states with smooth Core Animation transitions.

## States

### Compact (Pill)

The default resting state when sessions exist. A small horizontal pill showing:

- Aggregate crab icon (left side)
- Session count
- The most urgent status indicator (colored dot)

Dimensions: ~200x36 px. Rounded with full capsule corners.

### Expanded

Triggered by clicking the compact pill. Morphs outward to show the full session list:

- Each session row: crab icon, status dot, crab name, directory name, status label, elapsed time
- Full working directory path on second line
- Clickable rows for tmux focus (same as before)

Dimensions: ~420x(dynamic) px. Rounded corners (16px radius).

### No Sessions

When no sessions are active, the island collapses to a minimal dot or hides entirely.

## Visual Design

- **Background**: Dark translucent material (NSVisualEffectView with .dark appearance, .hudWindow material)
- **Text**: White/light gray for readability against dark background
- **Status colors**: Same semantic colors as before (green=working, red=needs input, orange=needs permission, gray=idle, pink=error)
- **Crab icon**: Same CrabRenderer, rendered at appropriate sizes
- **Corner radius**: Full capsule (height/2) for compact, 16px for expanded

## Animation

- **Expand/Collapse**: Spring animation on frame size change (~0.35s duration)
- **State transitions**: Smooth color crossfade when aggregate state changes
- **Crab animation**: Same 2fps timer-based animation as before

## Window Behavior

- `NSPanel` with `.nonactivatingPanel` style (clicking doesn't steal focus from other apps)
- Window level: `.floating` (above normal windows, below screen saver)
- No title bar, no shadow (custom drawing)
- Click outside to collapse back to compact state
- Draggable to reposition? (future consideration)

## Interaction

- **Click compact pill**: Expand to show session list
- **Click session row**: Focus tmux pane (same as before)
- **Click outside / press Escape**: Collapse to compact
- **Hover session row**: Subtle highlight

## Positioning

- Centered horizontally at the top of the main screen
- Y offset: ~6px below the top edge (just below the menu bar / notch area)
- Stays on the main display (follows NSScreen.main)

## Menu Bar Mode (Alternative Surface)

The same UI can be hosted in the macOS menu bar instead of a floating panel. The mode is selected at launch via `--menubar` (alias: `--statusbar`); the floating mode remains the default and is otherwise unchanged.

### Status Item

- Custom `NSStatusItem` with variable length
- Icon: the aggregate crab (rendered by `CrabRenderer`) plus a small state-coloured dot
- When more than one session is active, the session count is shown as the button title next to the icon
- Updates every animation tick (2 fps) so the working state animates in-place

### Panel

- The `IslandView` is reused unchanged, in always-expanded mode (`isExpanded = true`)
- The same `IslandPanel` (borderless non-activating `NSPanel`) is anchored just below the status item button
- Width: `expandedWidth` (440 px), or up to half the screen when a "Show full content" preview is open
- Height: same calculation as the floating expanded frame
- Clamped horizontally to the visible screen frame so it never goes off-edge

### Interaction

| Event | Behaviour |
|-------|-----------|
| Left-click status item | Toggle panel (show if hidden, hide if visible) |
| Right-click / Ctrl-click status item | Show context menu (Settings..., Quit) |
| Click anywhere outside the panel | Hide the panel (global `NSEvent` monitor) |
| Click a session row | Focus the terminal / tmux pane (same as floating mode) |
| Permission buttons | Same handler chain as floating mode |

### Differences vs. Floating Mode

- No compact pill at the top of the screen; the status item replaces it
- No expand/collapse animation -- the panel is simply shown or hidden
- The dock icon stays hidden in both modes (`setActivationPolicy(.accessory)`)
