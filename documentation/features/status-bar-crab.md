# Status Bar Crab

The status bar crab is the primary visual element of Claude Observer. It lives in the macOS menu bar and shows the aggregate state of all active Claude Code sessions.

## Appearance

The crab is rendered programmatically as an 18x18 pixel image using Core Graphics (`CGContext`). It is not a static asset but drawn in code, which allows frame-by-frame animation.

### Visual States

**Working (orange)**
- Body and claws in orange (`#FF7326`)
- Three pairs of legs wiggle alternately between frames
- Claws wave slightly
- Activity sparkles (yellow dots) cycle through three positions
- Eyes are open with pupils that look left/right

**Idle (gray)**
- Entire crab drawn at 40% opacity in gray tones
- Eyes are closed (half-circle arcs instead of full circles)
- Floating "z" characters drawn at top-right
- No leg or claw animation

**Needs Input / Needs Permission (red)**
- Body in red (`#FF4C33`)
- Crab scaled to 78% and shifted left to make room for badge
- Red notification badge with white "!" in top-right corner
- Bounces up by 1.5px on alternating frames
- Worried open mouth (small dark ellipse)

**Error (pink)**
- Body in pink (`#D926B2`)
- Same scaling and badge as "needs input" but with pink badge fill
- Worried expression

**None (no sessions)**
- Very faded gray crab at 25% opacity
- "zzz" overlay, same as idle

## Animation

The crab animates at 2 frames per second via a `Timer` with a 0.5-second interval. Each tick increments `animFrame`, which controls:

- Leg wiggle direction (`frame % 2`)
- Claw wave offset (`frame % 2`)
- Bounce offset for needs-input state (`frame % 2`)
- Sparkle position cycling (`frame % 3`)
- Pupil look direction (`frame % 4`)

## Session Count

A number is displayed next to the crab showing the total count of active sessions. When no sessions are active, the number is hidden.
