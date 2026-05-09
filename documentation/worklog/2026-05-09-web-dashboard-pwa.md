# Web Dashboard PWA

**Date:** 2026-05-09

**Task:** Build a Progressive Web App served from the Mac that acts as a phone dashboard for Claude Observer sessions, with live updates and permission response buttons — all on local network, no data leaves the network.

## Investigation

- iOS requires APNs for background push notifications — no local-network-only workaround exists
- A PWA served from the Mac and opened on the phone is the best privacy-preserving approach
- Network.framework (`NWListener`/`NWConnection`) provides modern TCP server capabilities on macOS
- CryptoKit provides `Insecure.SHA1` needed for the WebSocket handshake
- The existing poll loop in the app delegate already reads all session data every 2 seconds

## Changes

### `Sources/main.swift`

- **Imports**: Added `Network` and `CryptoKit`
- **Constants**: Added `kWebDir` for `~/.claude-observer/web/`
- **ObserverSettings**: Added `webDashboardEnabled` (Bool) and `webDashboardPort` (Int, default 9321) with backward-compatible decoder
- **`localIPAddress()`**: Detects LAN IP via `getifaddrs` for display in settings
- **`WebDashboardServer`**: New class (~200 lines) implementing:
  - TCP listener via `NWListener` on configured port
  - HTTP request handling: serves PWA HTML, manifest, sessions API, permission response endpoint
  - WebSocket upgrade handshake (SHA-1 via CryptoKit)
  - WebSocket frame encoding/decoding (text, close, ping/pong)
  - Client connection tracking and broadcasting
  - Permission response callback to app delegate
- **SettingsWindowController**: Added "Phone Dashboard (PWA)" section with enable checkbox, port field, and auto-detected URL display
- **ClaudeObserverDelegate**:
  - Starts/stops dashboard server based on settings
  - Broadcasts sessions to WebSocket clients on every poll cycle
  - Routes permission responses from web dashboard through existing response mechanism
  - Refactored `respondToPermission` to accept session ID directly (used by both Dynamic Island and web dashboard)

### `web/index.html` (new)

Single-file PWA (~665 lines) with:
- Dark theme matching Dynamic Island aesthetic
- Live session cards with status indicators and elapsed time
- Permission request cards with Allow/Deny/Always Allow buttons
- WebSocket connection with auto-reconnect (exponential backoff)
- Vibration and audio alerts for new permission requests
- PWA meta tags for iOS home screen installation
- Zero external dependencies

### Build system

- **Makefile**: Added `-framework Network` to swiftc, copies `web/index.html` to `~/.claude-observer/web/`
- **scripts/install.py**: Creates `web/` directory, copies HTML, adds `-framework Network` to compile command

### Documentation

- New: `documentation/features/web-dashboard.md`
- Updated: `documentation/features/README.md`

## Decisions

- **Raw TCP with NWListener** over higher-level frameworks: keeps zero external dependencies, handles both HTTP and WebSocket on same port
- **Single HTML file** for the PWA: trivial deployment, everything inline (CSS, JS, manifest as data URI)
- **WebSocket for live updates**: server broadcasts full session state on every poll cycle; client renders the diff
- **HTTP POST fallback** for permission responses: works even if WebSocket reconnects
- **Privacy-first**: no data leaves the local network. Tradeoff: no background push notifications (phone must have PWA open)
