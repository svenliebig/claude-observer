# 12. Glossary

| Term | Definition |
|------|-----------|
| Claude Code | Anthropic's CLI tool for interacting with Claude AI in a terminal. Supports a hook system for extending behavior. |
| Hook | A script invoked by Claude Code at specific lifecycle events (session start, stop, notification, etc.). Receives event data as JSON on stdin. |
| Session | A single running instance of Claude Code, identified by a unique session ID. |
| Crab Name | A human-friendly name (e.g., "Pinchy", "Clawdia") deterministically assigned to a session based on its ID. |
| Session File | A JSON file at `~/.claude-observer/sessions/{id}.json` containing the current state of a session. |
| Status Bar / Menu Bar | The macOS system area at the top of the screen where apps can place icons and dropdown menus. |
| `NSStatusItem` | The AppKit class representing an icon in the macOS status bar. |
| Accessory App | A macOS application running with `.accessory` activation policy - no Dock icon, no app menu. |
| Stale Session | A session whose corresponding Claude Code process has exited without firing a `SessionEnd` event. Detected via PID liveness check. |
| Atomic Write | Writing to a temporary file and then using `os.replace()` to move it into place, ensuring readers never see a partially-written file. |
| Poll Cycle | The 2-second interval at which the status bar app reads session files from disk. |
| Animation Frame | A counter incremented every 0.5 seconds, used to compute animation parameters (leg wiggle, bounce, sparkle position). |
