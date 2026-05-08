#!/usr/bin/env python3
"""Claude Observer Hook - tracks Claude Code session state for the status bar app."""

import json
import os
import sys
import hashlib
import time
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
tmux_pane = os.environ.get("TMUX_PANE", "")

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


def summarize_tool_input(tool_name, tool_input):
    if not tool_input or not isinstance(tool_input, dict):
        return ""
    if tool_name == "Bash":
        return tool_input.get("command", "")
    if tool_name in ("Edit", "Write", "Read"):
        path = tool_input.get("file_path", "")
        home = os.path.expanduser("~")
        if path.startswith(home):
            path = "~" + path[len(home):]
        return path
    if tool_name in ("Glob", "Grep"):
        return tool_input.get("pattern", "")
    if tool_name == "WebFetch":
        return tool_input.get("url", "")
    if tool_name == "WebSearch":
        return tool_input.get("query", "")
    for v in tool_input.values():
        if isinstance(v, str) and v:
            return v[:80]
    return ""


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
            "tmux_pane": tmux_pane,
        }
    if tmux_pane and not session.get("tmux_pane"):
        session["tmux_pane"] = tmux_pane
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
        "tmux_pane": tmux_pane,
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

elif event == "PostToolUse":
    session = ensure_session()
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "Notification":
    session = ensure_session()
    was_working = session.get("status") in ("working", None)
    session["status"] = "needs_input"
    session["notification_type"] = notification_type
    session["last_activity"] = timestamp
    write_session(session)
    if was_working:
        os.system("afplay /System/Library/Sounds/Ping.aiff &")

elif event == "PermissionRequest":
    session = ensure_session()
    was_working = session.get("status") in ("working", None)
    session["status"] = "needs_permission"
    session["last_activity"] = timestamp

    tool_name = data.get("tool_name", "Unknown")
    tool_input = data.get("tool_input", {})
    tool_summary = summarize_tool_input(tool_name, tool_input)
    session["permission_request"] = {
        "tool_name": tool_name,
        "tool_summary": tool_summary,
    }
    write_session(session)

    if was_working:
        os.system("afplay /System/Library/Sounds/Ping.aiff &")

    # Wait for response from the observer widget
    response_file = os.path.join(STATE_DIR, f"{session_id}.response.json")
    try:
        os.remove(response_file)
    except FileNotFoundError:
        pass

    start = time.time()
    while time.time() - start < 120:
        if os.path.exists(response_file):
            try:
                with open(response_file) as f:
                    response = json.load(f)
                os.remove(response_file)
            except Exception:
                break

            decision = response.get("decision", "allow")

            # Clear permission request from session
            session = read_session()
            if session:
                session.pop("permission_request", None)
                session["status"] = "working"
                session["last_activity"] = datetime.now(timezone.utc).strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
                write_session(session)

            if decision == "deny":
                sys.stderr.write("Denied via Claude Observer\n")
                sys.exit(2)

            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PermissionRequest",
                    "decision": {"behavior": "allow"},
                }
            }
            if decision == "always_allow":
                output["hookSpecificOutput"]["decision"]["permissionRule"] = tool_name
            json.dump(output, sys.stdout)
            sys.exit(0)

        time.sleep(0.5)

    # Timeout: clear permission_request, let Claude handle it normally
    session = read_session()
    if session:
        session.pop("permission_request", None)
        write_session(session)

elif event == "SubagentStart":
    session = ensure_session()
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "SubagentStop":
    session = ensure_session()
    session["last_activity"] = timestamp
    write_session(session)

elif event == "PreCompact":
    session = ensure_session()
    session["last_activity"] = timestamp
    write_session(session)

elif event == "SessionEnd":
    try:
        os.remove(session_file)
    except FileNotFoundError:
        pass
    try:
        os.remove(os.path.join(STATE_DIR, f"{session_id}.response.json"))
    except FileNotFoundError:
        pass
