# Crab Names

Each Claude Code session is assigned a unique crab name to make sessions easily distinguishable. Names are persistently tied to repositories so that the same "personality" always works in the same project.

## Persistent Repository Assignment

Names are assigned per-repository and stored in `~/.claude-observer/personalities.json`:

```json
{
  "~/git/dotfiles": ["Clawdia", "Pinchy"],
  "~/workspace/project-x": ["Snippy"]
}
```

### Assignment Algorithm

When a new session starts in a directory:

1. Load the personality map from `~/.claude-observer/personalities.json`
2. Normalize the cwd (replace `$HOME` with `~`)
3. Look up the repo's assigned name list
4. Find the first name in that list not currently used by an active session in the same directory
5. If all assigned names are in use, pick the first unassigned name from the global pool and append it to the repo's list
6. If all names in the pool are exhausted, steal a name randomly from another repo's list

### Guarantees

- The **first** name assigned to a repo is always the "primary" - it's the one used when only one session is open there
- Names persist across sessions and app restarts
- A name is never assigned to two different repositories simultaneously (unless stolen due to pool exhaustion)
- The same session always keeps its name for its entire lifetime

### Example Flow

1. User opens Claude in `~/git/dotfiles` -> assigns "Pinchy" (first available)
2. User opens a 2nd Claude in `~/git/dotfiles` -> assigns "Snippy" (next available, "Pinchy" is in use)
3. Both sessions end
4. User opens Claude in `~/git/dotfiles` again -> assigns "Pinchy" (first in list, not in use)

## Name Pool

There are 50 names available:

Pinchy, Snippy, Clawdia, Scuttles, Sheldon, Bubbles, Sandy, Hermie, Captain Claw, Rusty, Coral, Neptune, Barnacle, Tidbit, Shelly, Crusty, Wobbles, Chomper, Skipper, Pebbles, Biscuit, Snapper, Gizmo, Pepper, Ziggy, Pickle, Noodle, Sprocket, Tango, Mango, Fiddler, Coconut, Cheddar, Waffles, Bongo, Clementine, Puddles, Driftwood, Starfish, Jellybean, Anchovy, Ripple, Barnaby, Tempest, Breeze, Crumble, Scooter, Peanut, Sushi, Pretzel

## Name Exhaustion

When all 50 names are assigned to repositories, opening a session in a new repo triggers the steal mechanism: a random name is removed from another repo's list and assigned to the new repo. This keeps all repos functional at the cost of reassigning a secondary name from another project.
