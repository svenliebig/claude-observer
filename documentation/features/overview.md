# Feature Overview

Claude Observer is a macOS status bar application that visualizes running Claude Code sessions as animated crabs. It provides at-a-glance awareness of what each session is doing without switching between terminal windows.

## Core Features

| Feature | Description |
|---------|-------------|
| Animated Status Bar Crab | A pixel-art crab in the menu bar reflects the aggregate state of all sessions |
| Session Dropdown Menu | Click the crab to see each session's name, directory, and status |
| Unique Crab Names | Each session gets a deterministic name (Pinchy, Clawdia, etc.) from a pool of 35 |
| Stale Session Cleanup | Dead sessions are detected via PID checking and auto-removed after 5 minutes |
| Zero Configuration | Single `make install` command sets up everything |

## Session States

Each Claude Code session is tracked through these states:

| State | Visual | Trigger |
|-------|--------|---------|
| Working | Orange crab, wiggling legs, sparkles | `UserPromptSubmit`, `PreToolUse` |
| Idle | Gray faded crab, closed eyes, "zzz" | `Stop` |
| Needs Input | Red bouncing crab, "!" badge | `Notification` |
| Needs Permission | Red bouncing crab, "!" badge | `Notification` (permission type) |
| Error | Pink crab, "!" badge | `StopFailure` |
