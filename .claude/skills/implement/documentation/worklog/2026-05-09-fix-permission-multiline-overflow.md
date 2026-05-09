# Fix permission text overflowing buttons

**Date:** 2026-05-09

**Task:** Permission rows with multiline tool summaries overflow onto the action buttons. Make the row grow correctly to show the first 5 lines.

## Investigation

The permission row in `IslandView` used fixed dimensions:
- `permissionRowHeight = 85` (static constant)
- `buttonY_offset = 53` (static constant)
- Text truncated to 50 characters on a single line

When `toolSummary` contained newlines (e.g., multiline Bash commands), `NSAttributedString.draw(at:)` rendered them, causing vertical overflow onto the Allow/Deny/Always buttons.

## Changes

**File:** `Sources/main.swift`

- Removed fixed `permissionRowHeight` and `buttonY_offset` constants
- Added `permissionDisplayLines(for:)` — splits permission text by newlines, caps at 5 lines, truncates each line to 55 chars
- Added `permissionButtonYOffset(lineCount:)` — positions buttons below the actual text
- Added `permissionRowHeight(for:)` — computes row height dynamically based on line count
- Updated `rowHeight(for:)`, `mouseDown` (hit detection), `drawSessionRow` (rendering), and `expandedFrame()` (panel sizing) to use the dynamic calculations

## Decisions

- Max 5 lines shown, max 55 chars per line — fits the 440px expanded widget width with monospaced 10pt font
- Line height of 14px per line with 9px gap before buttons and 10px bottom padding
- For single-line text, layout is mathematically identical to the old fixed values (buttonY=53, rowHeight=85)
