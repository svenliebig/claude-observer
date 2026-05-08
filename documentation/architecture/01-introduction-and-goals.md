# 1. Introduction and Goals

## Requirements Overview

Claude Observer is a macOS status bar application that provides real-time visibility into running Claude Code sessions. Developers working with multiple parallel Claude Code instances need a way to know which sessions are active, which need input, and which have encountered errors - without switching between terminal windows.

### Key Requirements

| ID | Requirement |
|----|-------------|
| R1 | Display an animated crab icon in the macOS status bar reflecting aggregate session state |
| R2 | Show a dropdown menu listing all active sessions with their name, directory, and status |
| R3 | Send desktop notifications when a session transitions to a state requiring user input |
| R4 | Automatically detect and clean up stale sessions from crashed processes |
| R5 | Install and configure with a single command, requiring no manual setup |
| R6 | Assign each session a unique, human-friendly name for easy identification |

## Quality Goals

| Priority | Quality Goal | Description |
|----------|-------------|-------------|
| 1 | Responsiveness | State changes must be reflected in the status bar within 2 seconds |
| 2 | Reliability | The app must not crash or leak resources during extended operation |
| 3 | Simplicity | Zero external dependencies; single-command install and uninstall |
| 4 | Unobtrusiveness | No Dock icon, minimal resource usage, accessory-only app |

## Stakeholders

| Role | Expectations |
|------|-------------|
| Developer (user) | Glanceable overview of all Claude Code sessions; timely notifications when input is needed |
| Claude Code | Hook system is used non-intrusively; hook scripts exit quickly and do not block Claude Code's operation |
