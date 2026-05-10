# Expandable Permission Content

**Date:** 2026-05-09

**Task:** Add expandable content viewer for permission cards when text is too large, allowing users to show full content at 50% screen width with up to 80 lines.

## Investigation

- `web/index.html`: Permission content truncated to 10 lines via `truncateContent()`, displayed in `.permission-content` div with `max-height: 200px`
- `Sources/main.swift`: Code preview shows max 15 lines (`codeMaxVisibleLines`) with scroll support. Island width fixed at 440px (`expandedWidth`).

## Changes

### `web/index.html`
- Added `expandedSessions` Set state and `toggleExpand()` global function
- `buildCard()` detects truncatable content (>10 lines or >500 chars) and renders an expand toggle button showing line count
- When expanded: content shows up to 80 lines, card gets `.expanded` class (50vw width, centered via transform)
- CSS: `.card.expanded` breaks out of 500px container inline, `.permission-content` max-height increases to 1440px
- `.expand-toggle` styled as subtle bordered button matching the dark theme
- `.sessions` gets `overflow: visible` to allow expanded cards to break out
- Expanded state auto-clears when session no longer needs permission

### `Sources/main.swift`
- Added `expandedContentSessionId: String?` state on `IslandView`
- Added `codeMaxVisibleLinesExpanded = 80`, `expandToggleHeight = 24`, `contentIsTruncatable()` helper
- `codePreviewHeight()` and `permissionButtonY()` accept `expanded` parameter
- `rowHeight()` uses expanded state per session
- Drawing code renders a "Show full content (N lines)" toggle button below code preview when truncatable
- `mouseDown` detects clicks on the expand toggle area
- `onContentExpandToggle` callback triggers `resizeToFitContent()` on the controller
- `expandedFrame()` uses `max(440, screen.width * 0.5)` when content is expanded
- `drawCodePreview()` uses expanded max visible lines
- Scroll handler respects expanded max visible lines
- Expanded state clears on collapse and permission resolution

## Decisions
- Used inline expansion (not overlay) per user preference
- 50vw width with `min-width: 100%` ensures the card never shrinks below normal size on mobile
- Content expansion is per-session (only one can be expanded at a time in the Swift widget)
