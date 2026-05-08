# 4. Solution Strategy

## Key Design Decisions

### File-based IPC via JSON

Session state is communicated between the Python hook and the Swift app through JSON files on disk. This was chosen over alternatives (Unix sockets, shared memory, XPC) because:

- No process coordination needed - the hook and app can start/stop independently
- Session state survives app restarts (the app can pick up existing sessions on launch)
- Trivially debuggable - session files are human-readable JSON
- Atomic writes (`os.replace()`) prevent read-of-partial-write race conditions

### Polling over Push

The Swift app polls the sessions directory every 2 seconds rather than using `FSEvents` or file watchers. This was chosen for:

- Simplicity - no event subscription management or debouncing logic
- Reliability - polling naturally handles file creation, modification, and deletion
- 2-second latency is acceptable for a status indicator use case

### Single-file Swift Compilation

The status bar app is a single `main.swift` compiled with `swiftc` directly, avoiding Xcode projects or Swift Package Manager. This:

- Minimizes build tooling requirements (only Xcode CLT needed)
- Makes the build reproducible with a single shell command
- Keeps the project approachable - one file to read and understand

### Programmatic Crab Rendering

The crab is drawn using Core Graphics rather than bundled image assets. This enables:

- Frame-by-frame animation with varying parameters (leg wiggle, bounce, sparkle position)
- State-dependent rendering (color, expression, badges) without combinatorial asset explosion
- Pixel-perfect rendering at the exact status bar icon size

### Accessory App Mode

The app runs with `NSApplication.setActivationPolicy(.accessory)`, meaning:

- No Dock icon
- No application menu
- Invisible except for the status bar item
- Behaves as a background utility
