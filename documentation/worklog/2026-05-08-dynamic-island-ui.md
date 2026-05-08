# Dynamic Island UI

**Date:** 2026-05-08
**Task:** Rebuild the UI as a Dynamic Island floating panel, replacing the status bar icon + dropdown menu.

## Investigation

- The existing UI used `NSStatusBar` (18x18 crab icon) + `NSMenu` dropdown with custom `SessionMenuItemView` entries
- NSMenu doesn't support custom animations or smooth transitions
- The 18x18 icon severely limits visual richness
- Vibeisland.app was referenced as inspiration: a floating panel near the macOS notch area with smooth animations and dark translucent material

## Changes

### Replaced (`Sources/main.swift`)

**Removed:**
- `NSStatusBar` status item
- `NSMenu` + `SessionMenuItemView` dropdown system

**Added:**
- `IslandPanel` (NSPanel subclass): borderless, floating, non-activating, transparent, stays on all spaces
- `IslandView` (NSView subclass): handles all drawing and interaction for compact/expanded states
- `NSVisualEffectView` with `.hudWindow` material for dark translucent background
- Glow layer with colored shadow that pulses for attention states
- Animated expand/collapse using `NSAnimationContext` (0.3s/0.25s)
- Elapsed time display per session
- Right-click context menu for Quit (replaces menu item)
- `elapsedString(since:)` helper function

**Unchanged:**
- `CrabSession`, `CrabState`, `CrabRenderer` (all crab drawing code)
- Session polling, notification, tmux focus, duplicate detection logic
- Hook script, Makefile, install/uninstall scripts

### Documentation

- Created `documentation/features/dynamic-island.md` (feature spec)
- Added ADR-6 to `documentation/architecture/09-architecture-decisions.md`

## Decisions

- Used `NSPanel` with `.nonactivatingPanel` to avoid stealing focus from the user's active app
- Chose `.hudWindow` material for the native dark translucent look (matching macOS HUD aesthetic)
- Separated glow layer from content clipping layer so shadow extends beyond rounded corners
- Fixed compact width (240px with sessions, 160px without) for simplicity over dynamic calculation
- Used flipped coordinate system (`isFlipped = true`) for natural top-down layout
- Kept CrabRenderer unchanged — it works at any size and adapts well to the island context
- Added click-outside-to-collapse via `NSEvent.addGlobalMonitorForEvents` (removed on collapse)
- Animation guard (`isAnimating` flag) prevents frame conflicts when timers fire during transitions
