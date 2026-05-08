# Crab Names

Each Claude Code session is assigned a unique crab name to make sessions easily distinguishable.

## Name Assignment

Names are assigned deterministically from the session ID using an MD5 hash:

```python
name_idx = int(hashlib.md5(session_id.encode()).hexdigest(), 16) % len(CRAB_NAMES)
crab_name = CRAB_NAMES[name_idx]
```

This ensures:
- The same session always gets the same name (across hook invocations and app restarts)
- No coordination between the hook script and the Swift app is needed - both derive the name from the session ID independently
- Names are evenly distributed across the pool

## Name Pool

There are 35 names available:

Pinchy, Snippy, Clawdia, Scuttles, Sheldon, Bubbles, Sandy, Hermie, Captain Claw, Rusty, Coral, Neptune, Barnacle, Tidbit, Shelly, Crusty, Wobbles, Chomper, Skipper, Pebbles, Biscuit, Snapper, Gizmo, Pepper, Ziggy, Pickle, Noodle, Sprocket, Tango, Mango, Fiddler, Coconut, Cheddar, Waffles, Bongo

## Name Collisions

Since there are only 35 names and assignment is hash-based, two concurrent sessions could theoretically receive the same name. In practice this is rare with typical session counts (< 10). The sessions remain distinguishable by their working directory shown in the dropdown.
