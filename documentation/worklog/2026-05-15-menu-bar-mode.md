# Menu Bar Mode

**Date:** 2026-05-15
**Task:** Implement menu bar mode as alternative to floating Dynamic Island (from patch `0001-feat-add-menu-bar-mode-as-alternative-to-floating-Dy.patch`)

## Investigation

- The existing UI is a floating `IslandPanel` at the top of the screen with compact/expanded states
- `ClaudeObserverDelegate` owns the panel, glow, visual effect, and island views
- `IslandView` already supports an `isExpanded` property and all session/permission rendering
- `CrabRenderer.createImage` can render crabs at arbitrary sizes for the status item icon
- The entry point creates the delegate directly with no arguments

## Changes

### Sources/main.swift (+254 lines)
- Added `DisplayMode` enum with `.floating`/`.menubar` and CLI argument parser (`--menubar`, `--statusbar`, `--floating`)
- Added `init(displayMode:)` to `ClaudeObserverDelegate` with new properties: `displayMode`, `statusItem`, `menuBarPanelVisible`
- `applicationDidFinishLaunching` branches on display mode
- `setupMenuBar()` creates an `NSStatusItem` with the aggregate crab icon, state dot, and session count badge; reuses `IslandPanel`/`IslandView` in always-expanded mode
- Left-click toggles the session panel below the status item; right-click shows Settings/Quit menu; click-outside dismisses
- `menuBarPanelFrame()` positions the panel anchored below the status item, clamped to visible screen, with expanded-content width support
- `updateDisplay()` in menubar mode updates the status item image and resizes the panel if visible, then returns early
- Entry point parses `DisplayMode` from `CommandLine.arguments`

### Makefile (+4 lines)
- Added `run-menubar` target

### README.md (+19/-4 lines)
- Added menu bar mode to features list and Run section

### Documentation
- `features/dynamic-island.md`: Added "Menu Bar Mode" section describing status item, panel, interaction, and differences
- `technology/build-system.md`: Added `run-menubar` target, `-framework Network` note, "Runtime Flags" section

## Decisions / Trade-offs

- The `IslandView` is reused as-is in always-expanded mode rather than creating a separate menu bar view -- keeps code DRY and ensures feature parity
- The panel is shown/hidden rather than animated (no expand/collapse spring animation like floating mode) -- matches standard macOS menu bar popover behavior
- `NSEvent.addGlobalMonitorForEvents` handles click-outside dismissal -- standard pattern for menu bar popovers
- Status item icon uses `lockFocus`/`unlockFocus` drawing for the composite crab+dot image -- simple and matches the existing `CrabRenderer` approach
