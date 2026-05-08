# 11. Risks and Technical Debt

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Claude Code changes its hook system or event format | Medium | High - app stops receiving events | Hook script's input parsing is lenient; unknown events are silently ignored. Major hook API changes would require an update. |
| Multiple sessions receive the same crab name | Low | Low - cosmetic confusion | Sessions are also identified by working directory. The 35-name pool is sufficient for typical usage (< 10 concurrent sessions). |
| Session file write conflicts between concurrent hooks | Low | Low - temporary stale data | Atomic writes via `os.replace()` prevent partial reads. Worst case: one event's update overwrites another's, corrected on the next event. |
| Status bar app consumes too many resources | Low | Medium - user experience | Polling interval is 2 seconds. Animation redraws a single 18x18 image at 2 FPS. Resource usage is negligible. |

## Technical Debt

| Item | Description | Severity |
|------|-------------|----------|
| Duplicated crab name list | The 35 crab names are defined in both `main.swift` and `observer-hook.py`. Changes must be kept in sync manually. | Low |
| No automated tests | Neither the Swift app nor the Python hook script have unit tests. | Medium |
| Notification via osascript | Using `osascript` for notifications is a workaround for the lack of an app bundle. A proper `UNUserNotificationCenter` integration would provide richer notification features. | Low |
| No log output | The app produces no log files. Debugging requires adding print statements and running from a terminal. | Low |
| PID-based stale detection | Checking if a PID is alive via `kill(pid, 0)` can produce false positives if the PID has been reused by a different process. The 5-minute timeout mitigates this. | Low |
