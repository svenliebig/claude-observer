# Persistent Repository Personalities

**Date:** 2026-05-09
**Task:** Assign specific bot names to specific repositories persistently, so the same "personality" always works in the same project.

## Investigation

- Names were previously assigned via MD5 hash of session_id — deterministic per session but not tied to repositories
- The hook script (`observer-hook.py`) is responsible for all name assignment; the Swift app just reads the `name` field from session JSON files
- `kCrabNames` in `main.swift` is defined but never referenced — dead code kept for reference

## Changes

### `hooks/observer-hook.py`
- Replaced `hashlib` import with `random` (for the steal mechanism)
- Added `PERSONALITIES_FILE` constant (`~/.claude-observer/personalities.json`)
- Added personality management functions: `normalize_path()`, `load_personalities()`, `save_personalities()`, `get_active_names_for_cwd()`, `assign_personality()`
- Removed global MD5-based `crab_name` computation
- Changed `SessionStart` and `ensure_session()` to call `assign_personality(cwd, session_id)`
- Expanded `CRAB_NAMES` from 35 to 50 names

### `Sources/main.swift`
- Updated `kCrabNames` to match expanded 50-name list

### `documentation/features/crab-names.md`
- Rewritten to document the persistent per-repository assignment system

## Decisions

- **Storage format:** Simple JSON dict mapping normalized paths to ordered name lists. First name in list is the "primary" for that repo.
- **Name reuse:** When a session ends, its name becomes available again for the next session in that repo. The first name in the list is always preferred.
- **Exhaustion:** When all 50 names are assigned, a random name is stolen from another repo's list (popped from the end, so the primary name is preserved).
- **No cleanup:** Personality assignments persist forever. Only the steal mechanism removes names from a repo's list.
- **Concurrency:** Accepted minor race condition risk (two sessions starting simultaneously in the same repo could theoretically get the same name). Extremely unlikely in practice.
