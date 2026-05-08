# 9. Architecture Decisions

## ADR-1: File-based IPC over Sockets or XPC

**Context:** The hook script (Python) and the status bar app (Swift) need to exchange session state.

**Decision:** Use JSON files on disk as the communication mechanism.

**Rationale:**
- The hook and app have independent lifecycles - either can restart without breaking the other
- Session state survives app crashes and restarts
- Human-readable format aids debugging
- No connection management, handshaking, or protocol negotiation needed
- Atomic file writes (`os.replace()`) provide sufficient consistency guarantees

**Consequences:**
- Up to 2-second latency between state change and display update (polling interval)
- Disk I/O on every poll cycle (mitigated by the small number of files and their tiny size)

## ADR-2: Polling over File System Events

**Context:** The status bar app needs to detect changes to session files.

**Decision:** Poll the sessions directory every 2 seconds rather than using `FSEvents` or `DispatchSource`.

**Rationale:**
- Simpler implementation with no edge cases around event coalescing or missed events
- 2-second latency is acceptable for a status indicator
- Handles all change types uniformly (creation, modification, deletion)
- No need to manage watcher lifecycle or handle directory recreation

**Consequences:**
- Slightly higher CPU usage than event-driven approach (negligible in practice)
- Fixed 2-second maximum latency for state updates

## ADR-3: Single Swift File without Package Manager

**Context:** The app needs to be compiled and distributed.

**Decision:** Use a single `main.swift` file compiled directly with `swiftc`.

**Rationale:**
- Eliminates dependency on Swift Package Manager or Xcode
- Build command is a single, transparent shell invocation
- Easier for contributors to understand - everything is in one file
- No `Package.swift`, `.xcodeproj`, or `.xcworkspace` to maintain

**Consequences:**
- All code lives in one ~600-line file, which could become unwieldy if the app grows significantly
- No package dependency management (acceptable since there are zero dependencies)

## ADR-4: Notifications via osascript

**Context:** The app needs to send native macOS notifications.

**Decision:** Use `osascript -e 'display notification ...'` instead of `UNUserNotificationCenter`.

**Rationale:**
- No notification permission prompts required
- No app bundle or Info.plist needed
- Works reliably for a CLI-compiled binary without code signing
- Simpler implementation (single `Process` call)

**Consequences:**
- No notification actions (buttons, reply fields)
- No notification grouping or management
- Notification customization limited to title, body, and sound

## ADR-5: Programmatic Crab Drawing over Image Assets

**Context:** The status bar needs an animated, state-dependent icon.

**Decision:** Draw the crab programmatically using Core Graphics.

**Rationale:**
- Avoids combinatorial explosion of pre-rendered assets (5 states x N animation frames)
- Enables smooth parameter-driven animation (leg angle, bounce offset, sparkle position)
- No asset pipeline or image optimization needed
- Pixel-perfect at the exact rendering size

**Consequences:**
- Drawing code is verbose (~250 lines)
- Visual changes require code modifications rather than asset swaps
