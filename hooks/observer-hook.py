#!/usr/bin/env python3
"""Claude Observer Hook - tracks Claude Code session state for the status bar app."""

import json
import os
import subprocess
import sys
import random
import time
from datetime import datetime, timezone

STATE_DIR = os.path.expanduser("~/.claude-observer/sessions")
SETTINGS_FILE = os.path.expanduser("~/.claude-observer/settings.json")
PERSONALITIES_FILE = os.path.expanduser("~/.claude-observer/personalities.json")
os.makedirs(STATE_DIR, exist_ok=True)


def load_settings():
    try:
        with open(SETTINGS_FILE) as f:
            return json.load(f)
    except Exception:
        return {}


def play_sound(setting_key, default_sound):
    settings = load_settings()
    sound = settings.get(setting_key, default_sound)
    if sound:
        os.system(f"afplay /System/Library/Sounds/{sound}.aiff &")

CRAB_NAMES = [
    "Pinchy", "Snippy", "Clawdia", "Scuttles", "Sheldon",
    "Bubbles", "Sandy", "Hermie", "Captain Claw", "Rusty",
    "Coral", "Neptune", "Barnacle", "Tidbit", "Shelly",
    "Crusty", "Wobbles", "Chomper", "Skipper", "Pebbles",
    "Biscuit", "Snapper", "Gizmo", "Pepper", "Ziggy",
    "Pickle", "Noodle", "Sprocket", "Tango", "Mango",
    "Fiddler", "Coconut", "Cheddar", "Waffles", "Bongo",
    "Clementine", "Puddles", "Driftwood", "Starfish", "Jellybean",
    "Anchovy", "Ripple", "Barnaby", "Tempest", "Breeze",
    "Crumble", "Scooter", "Peanut", "Sushi", "Pretzel",
]


def normalize_path(path):
    home = os.path.expanduser("~")
    if path.startswith(home):
        return "~" + path[len(home):]
    return path


def load_personalities():
    try:
        with open(PERSONALITIES_FILE) as f:
            return json.load(f)
    except Exception:
        return {}


def save_personalities(data):
    tmp = PERSONALITIES_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, PERSONALITIES_FILE)


def get_active_names_for_cwd(normalized_cwd, exclude_session_id=None):
    """Get names currently used by active sessions in this cwd."""
    names = []
    try:
        for fname in os.listdir(STATE_DIR):
            if not fname.endswith(".json") or ".response." in fname:
                continue
            fpath = os.path.join(STATE_DIR, fname)
            try:
                with open(fpath) as f:
                    s = json.load(f)
                sid = s.get("id", "")
                if exclude_session_id and sid == exclude_session_id:
                    continue
                scwd = normalize_path(s.get("cwd", ""))
                if scwd == normalized_cwd:
                    names.append(s.get("name", ""))
            except Exception:
                continue
    except Exception:
        pass
    return names


def assign_personality(cwd_raw, session_id):
    """Assign a persistent personality name for a session in this directory."""
    normalized = normalize_path(cwd_raw)
    personalities = load_personalities()

    active_names = get_active_names_for_cwd(normalized, exclude_session_id=session_id)
    repo_names = personalities.get(normalized, [])

    # Find the first name in the assigned list not currently in use
    for name in repo_names:
        if name not in active_names:
            return name

    # All assigned names are in use (or none assigned yet) - get a new name
    all_assigned = set()
    for names_list in personalities.values():
        all_assigned.update(names_list)

    new_name = None
    for name in CRAB_NAMES:
        if name not in all_assigned:
            new_name = name
            break

    if new_name is None:
        # All names exhausted - steal from a random repo
        other_repos = [k for k, v in personalities.items() if k != normalized and len(v) > 0]
        if other_repos:
            victim_repo = random.choice(other_repos)
            new_name = personalities[victim_repo].pop()
            if not personalities[victim_repo]:
                del personalities[victim_repo]
        else:
            new_name = random.choice(CRAB_NAMES)

    repo_names.append(new_name)
    personalities[normalized] = repo_names
    save_personalities(personalities)
    return new_name

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = data.get("session_id", "unknown")
cwd = data.get("cwd", "")
event = data.get("hook_event_name", "unknown")
notification_type = data.get("notification_type", "")
tmux_pane = os.environ.get("TMUX_PANE", "")

KNOWN_TERMINALS = {
    "ghostty": "Ghostty",
    "terminal": "Terminal",
    "iterm2": "iTerm2",
    "wezterm-gui": "WezTerm",
    "alacritty": "Alacritty",
    "kitty": "kitty",
}


def detect_terminal_app():
    """Walk the process tree from our parent to find a known terminal app."""
    try:
        pid = os.getppid()
        for _ in range(20):
            if pid <= 1:
                break
            comm = os.popen(f"ps -p {pid} -o comm= 2>/dev/null").read().strip()
            ppid_str = os.popen(f"ps -p {pid} -o ppid= 2>/dev/null").read().strip()
            if not comm or not ppid_str:
                break
            # Check the basename of the executable against known terminals
            basename = os.path.basename(comm).lower()
            for key, name in KNOWN_TERMINALS.items():
                if key in basename:
                    return name
            pid = int(ppid_str)
    except Exception:
        pass
    return ""


terminal_app = detect_terminal_app()

session_file = os.path.join(STATE_DIR, f"{session_id}.json")
cancel_file = os.path.join(STATE_DIR, f"{session_id}.permission_cancel")
timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

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


TOOL_CATEGORIES = {
    "Write": "edits",
    "Edit": "edits",
    "NotebookEdit": "edits",
    "Bash": "bash",
    "Read": "file reads",
    "Glob": "file searches",
    "Grep": "file searches",
    "WebFetch": "web fetches",
    "WebSearch": "web searches",
}


def tool_category(tool_name):
    return TOOL_CATEGORIES.get(tool_name, tool_name.lower())


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
    if tool_name == "AskUserQuestion":
        questions = tool_input.get("questions", [])
        if questions and isinstance(questions, list):
            return questions[0].get("question", "")
        return ""
    for v in tool_input.values():
        if isinstance(v, str) and v:
            return v[:80]
    return ""


def ensure_session():
    session = read_session()
    if session is None:
        crab_name = assign_personality(cwd, session_id)
        session = {
            "id": session_id,
            "name": crab_name,
            "cwd": cwd,
            "status": "working",
            "pid": os.getppid(),
            "started_at": timestamp,
            "last_activity": timestamp,
            "tmux_pane": tmux_pane,
            "terminal_app": terminal_app,
        }
    if tmux_pane and not session.get("tmux_pane"):
        session["tmux_pane"] = tmux_pane
    if terminal_app and not session.get("terminal_app"):
        session["terminal_app"] = terminal_app
    return session


def signal_permission_handled(session):
    """If a permission request is pending, signal the polling loop to exit."""
    if session.get("status") != "needs_permission":
        return
    try:
        tmp = cancel_file + ".tmp"
        with open(tmp, "w") as f:
            f.write("1")
        os.replace(tmp, cancel_file)
    except Exception:
        pass
    session.pop("permission_request", None)


if event == "SessionStart":
    crab_name = assign_personality(cwd, session_id)
    session = {
        "id": session_id,
        "name": crab_name,
        "cwd": cwd,
        "status": "working",
        "pid": os.getppid(),
        "started_at": timestamp,
        "last_activity": timestamp,
        "tmux_pane": tmux_pane,
        "terminal_app": terminal_app,
    }
    write_session(session)

elif event == "UserPromptSubmit":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "PreToolUse":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "Stop":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "idle"
    session["last_activity"] = timestamp
    write_session(session)

elif event == "StopFailure":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "error"
    session["last_activity"] = timestamp
    write_session(session)
    play_sound("error_sound", "Basso")

elif event == "PostToolUse":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "Notification":
    session = ensure_session()
    # Don't overwrite an active permission request
    if session.get("status") == "needs_permission":
        # debug_log(f"Notification: skipped (status=needs_permission) session={session_id}")
        sys.exit(0)
    # debug_log(f"Notification: session={session_id} status->{session.get('status')}")
    was_working = session.get("status") in ("working", None)
    session["status"] = "needs_input"
    session["notification_type"] = notification_type
    session["last_activity"] = timestamp
    write_session(session)
    if was_working:
        play_sound("permission_sound", "Ping")

elif event == "PermissionRequest":
    # debug_log(f"PermissionRequest: session={session_id} tool={data.get('tool_name', '?')}")
    session = ensure_session()

    tool_name = data.get("tool_name", "Unknown")
    tool_input = data.get("tool_input", {})
    category = tool_category(tool_name)
    tool_summary = summarize_tool_input(tool_name, tool_input)

    # Auto-allow if this specific tool use was already allowed for this session
    if tool_summary and tool_summary in session.get("allowed_summaries", []):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PermissionRequest",
                "decision": {"behavior": "allow"},
            }
        }
        json.dump(output, sys.stdout)
        sys.exit(0)

    was_working = session.get("status") in ("working", None)
    session["status"] = "needs_permission"
    session["last_activity"] = timestamp
    perm = {
        "tool_name": tool_name,
        "tool_summary": tool_summary,
        "tool_category": category,
    }
    if tool_name == "Write" and isinstance(tool_input, dict):
        content = tool_input.get("content", "")
        if content:
            lines = content.split("\n")[:100]
            perm["tool_content"] = "\n".join(lines)
    if tool_name == "AskUserQuestion" and isinstance(tool_input, dict):
        questions = tool_input.get("questions", [])
        if questions and isinstance(questions, list):
            options = questions[0].get("options", [])
            perm["tool_options"] = [o.get("label", "") for o in options if isinstance(o, dict)]
    session["permission_request"] = perm
    write_session(session)
    # debug_log(f"  wrote session with needs_permission")

    if was_working:
        play_sound("permission_sound", "Ping")

    # Wait for response from the observer widget
    response_file = os.path.join(STATE_DIR, f"{session_id}.response.json")
    try:
        os.remove(response_file)
    except FileNotFoundError:
        pass
    try:
        os.remove(cancel_file)
    except FileNotFoundError:
        pass

    perm_data = perm

    start = time.time()
    while time.time() - start < 120:
        if os.path.exists(response_file):
            # debug_log(f"  response file found after {poll_count} polls")
            try:
                with open(response_file) as f:
                    response = json.load(f)
                os.remove(response_file)
                # debug_log(f"  response: {response}")
            except Exception as e:
                # debug_log(f"  FAILED to read response: {e}")
                break

            decision = response.get("decision", "allow")
            # debug_log(f"  decision: {decision}")

            # Clear permission request from session
            session = read_session()
            if session:
                session.pop("permission_request", None)
                session["status"] = "working"
                session["last_activity"] = datetime.now(timezone.utc).strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
                if decision == "always_allow" and tool_summary:
                    allowed = session.get("allowed_summaries", [])
                    if tool_summary not in allowed:
                        allowed.append(tool_summary)
                    session["allowed_summaries"] = allowed
                write_session(session)

            # For AskUserQuestion: type the answer into the terminal via tmux
            if tool_name == "AskUserQuestion" and decision != "deny":
                pane = (session or {}).get("tmux_pane", "")
                option_index = response.get("option_index")
                custom_answer = response.get("custom_answer")
                if pane and option_index is not None:
                    keys = ["Down"] * int(option_index) + ["Enter"]
                    subprocess.Popen(
                        ["bash", "-c", f"sleep 1.5 && tmux send-keys -t '{pane}' {' '.join(keys)}"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    )
                elif pane and custom_answer:
                    num_opts = len(perm_data.get("tool_options", []))
                    nav_keys = ["Down"] * num_opts + ["Enter"]
                    escaped = custom_answer.replace("'", "'\\''")
                    subprocess.Popen(
                        ["bash", "-c",
                         f"sleep 1.5 && tmux send-keys -t '{pane}' {' '.join(nav_keys)}"
                         f" && sleep 0.3 && tmux send-keys -t '{pane}' '{escaped}' Enter"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    )

            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PermissionRequest",
                    "decision": {"behavior": decision if decision == "deny" else "allow"},
                }
            }
            # debug_log(f"  -> exit 0 with output: {output}")
            json.dump(output, sys.stdout)
            sys.exit(0)

        # Check if permission was handled in the terminal
        if os.path.exists(cancel_file):
            try:
                os.remove(cancel_file)
            except Exception:
                pass
            session = read_session()
            if session:
                session.pop("permission_request", None)
                if session.get("status") == "needs_permission":
                    session["status"] = "working"
                session["last_activity"] = datetime.now(timezone.utc).strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
                write_session(session)
            sys.exit(0)

        # Re-assert permission status if overwritten by a concurrent event
        current = read_session()
        if current and (
            current.get("status") != "needs_permission"
            or "permission_request" not in current
        ):
            # debug_log(f"  re-assert: status was '{current.get('status')}', fixing")
            current["status"] = "needs_permission"
            current["permission_request"] = perm_data
            write_session(current)

        time.sleep(0.5)

    # Timeout: clear permission_request, let Claude handle it normally
    session = read_session()
    if session:
        session.pop("permission_request", None)
        if session.get("status") == "needs_permission":
            session["status"] = "working"
        write_session(session)

elif event == "SubagentStart":
    session = ensure_session()
    signal_permission_handled(session)
    session["status"] = "working"
    session["last_activity"] = timestamp
    if cwd:
        session["cwd"] = cwd
    write_session(session)

elif event == "SubagentStop":
    session = ensure_session()
    signal_permission_handled(session)
    session["last_activity"] = timestamp
    write_session(session)

elif event == "PreCompact":
    session = ensure_session()
    session["last_activity"] = timestamp
    write_session(session)

elif event == "SessionEnd":
    for path in [session_file,
                 os.path.join(STATE_DIR, f"{session_id}.response.json"),
                 cancel_file]:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass
