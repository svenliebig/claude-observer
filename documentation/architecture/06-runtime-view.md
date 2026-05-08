# 6. Runtime View

## Scenario 1: Session Start

```
Claude Code                Hook Script              Filesystem              Status Bar App
    |                          |                        |                        |
    |-- SessionStart event --->|                        |                        |
    |   (stdin JSON)           |                        |                        |
    |                          |-- write {id}.json ---->|                        |
    |                          |   status: "working"    |                        |
    |                          |                        |                        |
    |                          |                        |<-- poll (2s timer) ----|
    |                          |                        |--- session data ------>|
    |                          |                        |                        |-- update icon
    |                          |                        |                        |-- rebuild menu
```

## Scenario 2: Session Needs Input (Notification)

```
Claude Code                Hook Script              Filesystem              Status Bar App
    |                          |                        |                        |
    |-- Notification event --->|                        |                        |
    |   (stdin JSON)           |                        |                        |
    |                          |-- update {id}.json --->|                        |
    |                          |   status: "needs_input"|                        |
    |                          |-- afplay Ping.aiff     |                        |
    |                          |                        |                        |
    |                          |                        |<-- poll (2s timer) ----|
    |                          |                        |--- session data ------>|
    |                          |                        |                        |-- update icon (red)
    |                          |                        |                        |-- rebuild menu
    |                          |                        |                        |-- osascript notification
```

## Scenario 2b: Session Needs Permission

```
Claude Code                Hook Script              Filesystem              Status Bar App
    |                          |                        |                        |
    |-- PermissionRequest ---->|                        |                        |
    |   (stdin JSON)           |                        |                        |
    |                          |-- update {id}.json --->|                        |
    |                          |   status:              |                        |
    |                          |    "needs_permission"  |                        |
    |                          |-- afplay Ping.aiff     |                        |
    |                          |                        |                        |
    |                          |                        |<-- poll (2s timer) ----|
    |                          |                        |--- session data ------>|
    |                          |                        |                        |-- update icon (orange)
    |                          |                        |                        |-- rebuild menu
    |                          |                        |                        |-- osascript notification
```

## Scenario 3: Session End

```
Claude Code                Hook Script              Filesystem              Status Bar App
    |                          |                        |                        |
    |-- SessionEnd event ----->|                        |                        |
    |   (stdin JSON)           |                        |                        |
    |                          |-- delete {id}.json --->|                        |
    |                          |                        |                        |
    |                          |                        |<-- poll (2s timer) ----|
    |                          |                        |   (file gone)          |
    |                          |                        |                        |-- remove from sessions
    |                          |                        |                        |-- update icon
    |                          |                        |                        |-- rebuild menu
```

## Scenario 4: Stale Session Cleanup

```
                                                    Filesystem              Status Bar App
                                                        |                        |
(Claude Code crashes, no SessionEnd fired)              |                        |
                                                        |<-- poll (2s timer) ----|
                                                        |--- session data ------>|
                                                        |                        |-- kill(pid, 0) -> ESRCH
                                                        |                        |-- last_activity > 5min ago
                                                        |<-- delete {id}.json ---|
                                                        |                        |-- remove from sessions
```

## Scenario 5: App Startup

```
Status Bar App
    |
    |-- applicationDidFinishLaunching()
    |   |-- isDuplicate() -> check via pgrep
    |   |-- create sessions directory (if missing)
    |   |-- create NSStatusItem
    |   |-- pollSessions() (initial load)
    |   |-- start pollTimer (2s interval)
    |   |-- start animTimer (0.5s interval)
    |   |-- updateDisplay()
```
