# Crab Color Setting

**Date:** 2026-05-15
**Task:** Add that you can set the color of the main crab in the settings

## Investigation

- The crab is rendered programmatically in `CrabRenderer.drawCrab()` with hardcoded colors per state (working=orange, idle=gray, needsInput=red, error=pink).
- Settings follow a consistent pattern: field in `ObserverSettings` struct, UI control in `SettingsWindowController`, read at runtime via `ObserverSettings.load()`.
- The animation timer already loads settings every tick (0.5s) to check `disableMotion`. The custom color piggybacks on this existing load.
- The menu bar crab is rendered in `updateStatusItemImage()` in the delegate; widget crabs are rendered inside `IslandView`.

## Changes

### `Sources/main.swift`
- **`ObserverSettings`**: Added `changeCrabColor: Bool` (`"change_crab_color"`, default `false`) and `crabColor: String` (`"crab_color"`, default `""`).
- **`CrabRenderer`**: Added `parseHexColor(_:)` helper, optional `customColor` parameter on `createImage`/`drawCrab`. When set, overrides body/shell color for **all** crab states (with appropriate alpha for idle/none). Notification badge ("!") is unaffected.
- **`ClaudeObserverDelegate`**: Timer stores `menuBarCrabColor` (color string or `nil` depending on `changeCrabColor` toggle). Only the menu bar renderer passes this to `CrabRenderer`.
- **`IslandView`**: No color property — widget crabs always use default state colors.
- **`SettingsWindowController`**: Added "Change crab color" checkbox + `NSColorWell` + "Reset" button. Color well and reset are hidden when checkbox is off. Window height increased by 34px.

### `documentation/features/settings.md`
- Added `change_crab_color` and `crab_color` to JSON schema and Display Settings table.

## Decisions

- Custom color only applies to the **menu bar crab**, not the floating widget crabs — keeps widget crabs visually consistent with state semantics.
- Custom color applies to **all states** (working, idle, needsInput, error, none) with alpha adjustments for idle/none. The notification badge keeps its own red/pink color.
- A boolean toggle gates the feature — when off, no custom color is applied anywhere.
- Shell color is auto-derived (85% of body) rather than requiring a second color pick.
- Used `NSColorWell` (native macOS color picker) for better UX.
- The "Reset" button reverts to default orange without disabling the feature.
