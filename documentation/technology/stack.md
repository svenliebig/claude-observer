# Technology Stack

## Languages

| Language | Version | Purpose |
|----------|---------|---------|
| Swift | 5.x+ (ships with Xcode CLT) | Status bar application |
| Python | 3.x (ships with macOS / Xcode CLT) | Hook script, install/uninstall scripts |

## Frameworks and APIs

### Swift / macOS

| Framework / API | Usage |
|-----------------|-------|
| `Cocoa` (`AppKit`) | `NSApplication`, `NSStatusBar`, `NSMenu`, `NSMenuItem` for the status bar app |
| `CoreGraphics` (`CGContext`) | Programmatic crab rendering (drawing ellipses, lines, arcs, text) |
| `Foundation` | `FileManager`, `JSONDecoder`, `Timer`, `Process`, `ISO8601DateFormatter` |

### Python Standard Library

| Module | Usage |
|--------|-------|
| `json` | Reading/writing session state files and Claude Code settings |
| `hashlib` | MD5 hash for deterministic crab name assignment |
| `os` | File operations, environment, process management |
| `shutil` | File copying during installation |
| `subprocess` | Swift compilation during installation |
| `datetime` | ISO 8601 timestamps for session activity tracking |

## System Dependencies

| Dependency | Required For |
|------------|-------------|
| macOS 12+ | Minimum OS version for AppKit APIs used |
| Xcode Command Line Tools | `swiftc` compiler |
| Python 3 | Hook script execution, install/uninstall scripts |
| `osascript` | Desktop notifications via AppleScript |
| `afplay` | Playing system sounds (Ping.aiff, Basso.aiff) |
| `pgrep` | Duplicate instance detection |

## External Dependencies

None. Claude Observer has zero third-party dependencies. It relies entirely on macOS system frameworks and the Python standard library.
