#!/usr/bin/env python3
"""Claude Observer Hook - tracks Claude Code session state for the status bar app."""

import json
import os
import sys
import hashlib
from datetime import datetime, timezone

STATE_DIR = os.path.expanduser("~/.claude-observer/sessions")
os.makedirs(STATE_DIR, exist_ok=True)

CRAB_NAMES = [
    "Pinchy", "Snippy", "Clawdia", "Scuttles", "Sheldon",
    "Bubbles", "Sandy", "Hermie", "Captain Claw", "Rusty",
    "Coral", "Neptune", "Barnacle", "Tidbit", "Shelly",
    "Crusty", "Wobbles", "Chomper", "Skipper", "Pebbles",
    "Biscuit", "Snapper", "Gizmo", "Pepper", "Ziggy",
    "Pickle", "Noodle", "Sprocket", "Tango", "Mango",
    "Fiddler", "Coconut", "Cheddar", "Waffles", "Bongo"
]

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = data.get("session_id", "unknown")
cwd = data.get("cwd", "")
event = data.get("hook_event_name", "unknown")
notification_type = data.get("notification_type", "")

session_file = os.path.join(STATE_DIR, f"{session_id}.json")
timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Deterministic crab name from session ID
name_idx = int(hashlib.md5(session_id.encode()).hexdigest(), 16) % len(CRAB_NAMES)
crab_name = CRAB_NAMES[name_idx]


def read_session():
    try:
        with open(session_file) as f:
            return json.load(f)
    except Exception:
        return None


def write_session(session):
    tmp = session_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(session, f)
    os.replace(tmp, session_file)


def ensure_session():
    session = read_session()
    if session is None:
        session = {
            "id": session_id,
            "name": crab_name,
            "cwd": cwd,
            "status": "working",
            "pid": os.getppid(),
            "started_at": timestamp,
            "last_activity": timestamp,
        }
    return session


if event == "SessionStart":
    session = {
        "id": session_id,
        "name": crab_name,
        "cwd": cwd,
        "status": "working",
        "pid": os.getppid(),
        "started_at": timestamp,
        "last_activity": timestamp,
    }
    write_session(session)

elif event == "UserPromptSubmit":
    session = ensure_session()
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "PreToolUse":
    session = ensure_session()
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "Stop":
    session = ensure_session()
    session["status"] = "idle"
    session["last_activity"] = timestamp
    write_session(session)

elif event == "StopFailure":
    session = ensure_session()
    session["status"] = "error"
    session["last_activity"] = timestamp
    write_session(session)
    os.system("afplay /System/Library/Sounds/Basso.aiff &")

elif event == "Notification":
    session = ensure_session()
    was_working = session.get("status") in ("working", None)
    session["status"] = "needs_input"
    session["notification_type"] = notification_type
    session["last_activity"] = timestamp
    write_session(session)
    if was_working:
        os.system("afplay /System/Library/Sounds/Ping.aiff &")

elif event == "SessionEnd":
    try:
        os.remove(session_file)
    except FileNotFoundError:
        pass
