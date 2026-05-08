# 2. Constraints

## Technical Constraints

| Constraint | Description |
|------------|-------------|
| macOS only | The app uses `NSStatusBar`, `NSMenu`, and other AppKit APIs that are macOS-exclusive |
| macOS 12+ | Minimum deployment target due to API requirements |
| Xcode Command Line Tools | Required for the `swiftc` compiler |
| Python 3 | Required for hook scripts; ships with macOS and Xcode CLT |
| Claude Code hook system | The application depends on Claude Code's hook mechanism for session tracking |
| No third-party dependencies | The project uses only macOS system frameworks and the Python standard library |

## Organizational Constraints

| Constraint | Description |
|------------|-------------|
| Single-file Swift | The status bar app is a single `main.swift` file compiled directly with `swiftc`, avoiding the need for Xcode projects or Swift Package Manager |
| File-based IPC | Communication between the hook script and the status bar app is exclusively through JSON files on the filesystem |

## Conventions

| Convention | Description |
|------------|-------------|
| State directory | All runtime state is stored under `~/.claude-observer/` |
| Session files | One JSON file per session at `~/.claude-observer/sessions/{session_id}.json` |
| Hook registration | Hooks are registered in `~/.claude/settings.json` under the `hooks` key |
| Timestamps | All timestamps use ISO 8601 format in UTC |
