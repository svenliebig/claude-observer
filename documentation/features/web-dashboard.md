# Web Dashboard (PWA)

Claude Observer can serve a Progressive Web App (PWA) that acts as a remote dashboard on your phone. It shows live session status and allows responding to permission requests — all within your local network.

## Overview

The Swift app embeds a lightweight HTTP + WebSocket server. Your phone opens the dashboard URL in a browser and can install it as a PWA on the home screen. The WebSocket connection delivers real-time session updates; no polling, no cloud services, no data leaves your network.

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `web_dashboard_enabled` | `false` | Enable/disable the web dashboard server |
| `web_dashboard_port` | `9321` | Port for the HTTP + WebSocket server |

## How It Works

### Server (Swift app)

The app starts an HTTP + WebSocket server on the configured port when enabled:

- **HTTP `GET /`** — serves the PWA HTML page
- **HTTP `GET /manifest.json`** — serves the PWA manifest
- **HTTP `GET /api/sessions`** — returns current session state as JSON (for initial load)
- **HTTP `POST /api/permission-response`** — receives permission decisions from the phone
- **WebSocket `ws://<ip>:<port>/ws`** — streams session state changes in real-time

### Client (PWA on phone)

A single-page app that:

- Connects via WebSocket on load, with HTTP polling fallback (every 2s) if WebSocket fails
- Displays all active sessions with status (working, idle, needs_input, needs_permission, error)
- Shows permission request cards with tool name, summary, and optional code preview
- Provides Allow / Deny / Always Allow buttons for permission requests (sent via WebSocket or HTTP POST fallback)
- Plays a sound and vibrates when a permission request or error arrives
- Reconnects automatically if the WebSocket connection drops
- Smart re-rendering: DOM only rebuilds when session status or permission state changes, not on every poll; elapsed times update in-place via lightweight timer

### Permission Response Flow

```
Phone taps "Allow"
        |
        v
POST /api/permission-response
  { "session_id": "...", "decision": "allow" }
        |
        v
Swift app writes {session_id}.response.json
        |
        v
Hook script picks up the response
```

## PWA Features

- **Installable**: Add to home screen from Safari/Chrome, launches without browser chrome
- **Offline fallback**: Shows "Connecting..." state when the Mac is unreachable
- **Theme**: Dark theme matching the Dynamic Island aesthetic
- **Responsive**: Designed for phone screen sizes

## Phone Setup

1. Enable the web dashboard in Claude Observer settings
2. On your phone, open `http://<mac-ip>:9321` in Safari/Chrome
3. Add to home screen (Share > Add to Home Screen)
4. The PWA icon appears on your home screen

The settings window shows the URL with the auto-detected LAN IP.

## Architecture

- **No external dependencies**: The HTTP/WebSocket server is built with raw Swift sockets (Foundation `NWListener`/`NWConnection` from Network.framework)
- **Single HTML file**: The entire PWA (HTML + CSS + JS + manifest) is served as a single response, keeping deployment trivial
- **Session data reuse**: The server broadcasts the same session data the app already polls from `~/.claude-observer/sessions/`

## Limitations

- Phone must have the PWA open (screen on, tab active) to receive updates
- No background push notifications — this is a conscious privacy tradeoff
- Works best as a desk companion (phone on a stand)
