# Notifications

Claude Observer plays sounds to alert the user when a session requires attention. Visual alerts are handled by the Dynamic Island UI.

## Sound Alerts

Two distinct sounds are used:

| Event | Sound | Triggered By |
|-------|-------|-------------|
| Session needs input | `Ping.aiff` | Hook script (`afplay`) when transitioning from `working` to `needs_input` |
| Session error | `Basso.aiff` | Hook script (`afplay`) on `StopFailure` event |

The Ping sound is played by the hook script only when the session was previously in a `working` state, preventing duplicate sounds on repeated notification events.
