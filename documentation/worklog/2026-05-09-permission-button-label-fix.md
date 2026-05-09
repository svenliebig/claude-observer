# Fix permission button label to match CLI

**Date:** 2026-05-09

## Task

The widget's "Allow all bash" button didn't match the CLI's "Yes, and don't ask again for: \<specific command\>" option. The widget should reflect the actual command being allowed.

## Investigation

- The widget used `toolCategory` (e.g., "bash", "edits") for the third button label
- The CLI shows the specific command/path in its "don't ask again" option
- The hook's `always_allow` behavior stored `allowed_categories`, allowing ALL tools in a category — much broader than the CLI's per-command allowance

## Changes

### `Sources/main.swift`
- Changed `buttonSpecs` to use `toolSummary` in the button label instead of `toolCategory`
- Label now shows the specific command/path (e.g., "Allow all npm run build 2>&1 && npm -w …")
- Truncates at 30 characters with ellipsis; falls back to category if summary is empty

### `hooks/observer-hook.py`
- Changed `allowed_categories` to `allowed_summaries` for auto-allow storage
- Auto-allow now checks exact tool summary match instead of broad category match
- Moved `tool_summary` computation before the auto-allow check

### `documentation/features/permission-response.md`
- Updated button description and always_allow hook output documentation

## Decisions

- Used exact summary matching for auto-allow (stricter than category-based, matching CLI behavior)
- Kept "Allow all" prefix on the button for consistency, appending the truncated summary
- 30-char truncation balances readability with available button space
