# 10. Quality Requirements

## Quality Tree

```
Quality
|-- Responsiveness
|   +-- State updates visible within 2 seconds
|-- Reliability
|   |-- No crashes during extended operation
|   |-- Graceful handling of corrupt/missing session files
|   +-- Automatic stale session cleanup
|-- Simplicity
|   |-- Zero external dependencies
|   |-- Single-command install/uninstall
|   +-- Single-file main application
|-- Unobtrusiveness
|   |-- No Dock icon (accessory app)
|   |-- Minimal CPU usage
|   +-- Single instance enforcement
```

## Quality Scenarios

| ID | Quality Attribute | Scenario | Expected Behavior |
|----|------------------|----------|-------------------|
| QS-1 | Responsiveness | A Claude Code session starts | The crab count and menu update within 2 seconds |
| QS-2 | Responsiveness | A session needs input | Notification appears and sound plays within 2 seconds |
| QS-3 | Reliability | Claude Code crashes without firing SessionEnd | Stale session is cleaned up within 5 minutes after process death |
| QS-4 | Reliability | A session JSON file is corrupted | The file is silently skipped; other sessions display normally |
| QS-5 | Reliability | The status bar app is restarted | All existing sessions are picked up from disk on the next poll |
| QS-6 | Simplicity | User runs `make install` | App compiles, hooks install, settings configure - no further steps needed |
| QS-7 | Simplicity | User runs `make uninstall` | All hooks, binaries, and state are removed cleanly |
| QS-8 | Unobtrusiveness | App is running | No Dock icon visible, no windows, no app menu |
| QS-9 | Unobtrusiveness | User launches the app twice | Second instance detects the first and exits immediately |
| QS-10 | Unobtrusiveness | Hook script encounters an error | Script exits silently; Claude Code operation is not blocked |
