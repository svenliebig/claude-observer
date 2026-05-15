# Disable Motion Setting

**Date:** 2026-05-15
**Task:** Add a setting to disable the crab's motion animation, called "Disable motion".

## Investigation

- The crab animation is driven by `animFrame`, incremented every 0.5s in a `Timer` callback in `ClaudeObserverDelegate`.
- `animFrame` controls leg wiggle, claw wave, bounce, sparkle position, pupil direction, and glow pulse.
- Settings are stored in `ObserverSettings` (Codable struct) at `~/.claude-observer/settings.json`.
- The settings window (`SettingsWindowController`) uses manual `NSView` layout with sections separated by `NSBox` separators.

## Changes

### `Sources/main.swift`
- **`ObserverSettings`**: Added `disableMotion: Bool` property with coding key `disable_motion`, default `false`, and decoder fallback.
- **`SettingsWindowController`**: Added a "Display" section between Sound and Web Dashboard containing a "Disable motion" checkbox. Window height increased from 310 to 370.
- **Animation timer**: When `disableMotion` is `true`, `animFrame` is reset to `0` instead of incrementing, freezing the crab in its static pose.

### `documentation/features/settings.md`
- Added `disable_motion` to schema example and a new "Display Settings" table.

## Decisions

- Setting is read from disk in the timer callback (2x/sec). The settings file is tiny JSON so this is negligible overhead and avoids needing a notification/callback mechanism for setting changes.
- When motion is disabled, `animFrame` is set to `0` (not just frozen at its current value) so the crab always shows a consistent static pose.
