# 3. Context and Scope

## Business Context

```
+-------------------+          hook events          +-------------------+
|                   | --(stdin JSON)--------------> |                   |
|   Claude Code     |                               |   Observer Hook   |
|   (CLI session)   |                               |   (Python)        |
|                   |                               |                   |
+-------------------+                               +--------+----------+
                                                             |
                                                    writes JSON files
                                                             |
                                                             v
                                                    +--------+----------+
+-------------------+          reads files          |  ~/.claude-       |
|                   | <---------------------------- |  observer/        |
|   Status Bar App  |                               |  sessions/        |
|   (Swift)         |                               |                   |
|                   |                               +-------------------+
+--------+----------+
         |
         |  displays
         v
+-------------------+
|   macOS Menu Bar  |
|   + Dynamic Island|
+-------------------+
         |
         v
+-------------------+
|   Developer       |
|   (User)          |
+-------------------+
```

### External Interfaces

| Neighbor | Interface | Description |
|----------|-----------|-------------|
| Claude Code | stdin JSON via hook system | Claude Code invokes the hook script with event data on stdin for each lifecycle event |
| macOS Menu Bar | `NSStatusBar` API | The Swift app renders a status item with icon and dropdown menu |
| macOS Audio | `afplay` | System sounds are played for input-needed and error events |
| Filesystem | JSON files | Session state is communicated between hook and app via JSON files |

## Technical Context

```
+-----------------------+     +-----------------------+     +-------------------+
| Claude Code Process   |     | observer-hook.py      |     | claude-observer   |
| (any terminal)        |     | (Python 3)            |     | (Swift/AppKit)    |
|                       |     |                       |     |                   |
| Triggers hooks on:    |     | Reads stdin JSON      |     | Polls sessions/   |
| - SessionStart        |---->| Writes/updates/deletes|---->| dir every 2s      |
| - SessionEnd          |     | session JSON files    |     | Renders crab icon |
| - UserPromptSubmit    |     | Plays sounds          |     | Builds menu       |
| - PreToolUse          |     |                       |     |                   |
| - PostToolUse         |     +-----------------------+     +-------------------+
| - Stop                |
| - StopFailure         |
| - Notification        |
| - PermissionRequest   |
| - PreCompact          |
| - SubagentStart       |
| - SubagentStop        |
+-----------------------+
```

The hook script and status bar app are decoupled - they share no process, memory, or direct communication channel. The filesystem serves as the sole integration point.
