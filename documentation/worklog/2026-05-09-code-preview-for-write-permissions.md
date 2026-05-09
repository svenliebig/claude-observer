# Code Preview for Write Permissions

**Date**: 2026-05-09
**Task**: Add scrollable code preview with syntax highlighting above accept/deny buttons for file write permission requests.

## What was investigated

- Permission request data flow from hook to widget
- Existing permission row rendering (text-only with tool name + summary)
- `tool_input` structure for Write tool (contains `file_path` and `content`)
- Custom drawing approach in IslandView (Core Graphics + NSAttributedString)

## What was changed

### Hook (`hooks/observer-hook.py`)
- When the tool is `Write`, extract the `content` field from `tool_input` and include the first 100 lines as `tool_content` in the `permission_request` object

### Data model (`Sources/main.swift`)
- Added `toolContent: String?` to `PermissionRequestInfo` struct

### UI (`Sources/main.swift`)
- Added code preview constants (line height, font size, max visible lines, padding, line number width)
- Added scroll state (`codeScrollOffset`, `codePreviewSessionId`) with `scrollWheel` override
- Added `drawCodePreview()`: dark rounded background, line number gutter with separator, syntax-highlighted code, scroll indicator
- Added syntax highlighting via regex-based tokenization:
  - JSON: keys (cyan), strings (orange), numbers (green), booleans/null (purple)
  - Generic fallback: strings, numbers, comments
- Updated `permissionButtonY()` and `permissionRowHeight()` to handle code preview layout
- Existing text-only permission display preserved for non-Write tools

## Decisions and trade-offs

- Used custom Core Graphics drawing (consistent with existing approach) rather than embedding NSScrollView/NSTextView
- Limited to 15 visible lines with manual scroll tracking to keep the widget compact
- Hook sends max 100 lines to keep session JSON files small
- Simple regex-based syntax highlighting — good enough for quick review without adding dependencies
