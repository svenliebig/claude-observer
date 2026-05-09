# Settings and Sound Configuration

**Date:** 2026-05-09

**Task:** Add a settings system accessible from the right-click context menu, with configurable sound settings for permission requests and errors.

## Investigation

- Right-click menu existed in `IslandView.rightMouseDown()` with only "Quit Claude Observer"
- Sounds were hardcoded in `hooks/observer-hook.py` via `afplay` calls: `Ping.aiff` for notifications/permissions, `Basso.aiff` for errors
- 14 system sounds available in `/System/Library/Sounds/`
- No settings persistence existed

## Changes

### `Sources/main.swift`
- Added `kSettingsFile` (`~/.claude-observer/settings.json`) and `kSystemSounds` (auto-discovered from system)
- Added `ObserverSettings` Codable struct with `permissionSound` and `errorSound`, plus `load()`/`save()`
- Added `SettingsWindowController` with two dropdowns (permission sound, error sound) and a preview button
- Extended right-click menu with "Settings..." item above a separator
- Wired settings window via `islandView.onOpenSettings` callback in `ClaudeObserverDelegate`

### `hooks/observer-hook.py`
- Added `load_settings()` and `play_sound(setting_key, default_sound)` helper
- Replaced 3 hardcoded `afplay` calls with `play_sound()` which reads settings and skips if sound is disabled (empty string)

### `documentation/features/settings.md`
- New feature documentation for the settings system

## Decisions

- Settings are saved immediately on dropdown change (no explicit save button)
- Both Swift app and Python hook read the same JSON file; only the Swift app writes it
- "None (disabled)" maps to an empty string in the JSON, which causes the hook to skip the `afplay` call
- System sounds are auto-discovered at launch rather than hardcoded
