#!/usr/bin/env python3
"""Install Claude Observer: compile app, copy hooks, configure settings."""

import json
import os
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
OBSERVER_DIR = os.path.join(HOME, ".claude-observer")
SETTINGS_FILE = os.path.join(HOME, ".claude", "settings.json")
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    print("Installing Claude Observer...")
    print()

    # Create directories
    for d in ["bin", "hooks", "sessions", "web"]:
        os.makedirs(os.path.join(OBSERVER_DIR, d), exist_ok=True)

    # Copy web assets
    src_web = os.path.join(PROJECT_DIR, "web", "index.html")
    dst_web = os.path.join(OBSERVER_DIR, "web", "index.html")
    if os.path.exists(src_web):
        shutil.copy2(src_web, dst_web)
        print(f"  Web dashboard -> {dst_web}")

    # Copy hook script
    src_hook = os.path.join(PROJECT_DIR, "hooks", "observer-hook.py")
    dst_hook = os.path.join(OBSERVER_DIR, "hooks", "observer-hook.py")
    shutil.copy2(src_hook, dst_hook)
    os.chmod(dst_hook, 0o755)
    print(f"  Hook script -> {dst_hook}")

    # Compile Swift app
    swift_src = os.path.join(PROJECT_DIR, "Sources", "main.swift")
    binary = os.path.join(OBSERVER_DIR, "bin", "claude-observer")
    print("  Compiling status bar app...")

    result = subprocess.run(
        ["swiftc", "-O", "-o", binary, swift_src, "-framework", "Cocoa", "-framework", "Network"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  Compilation failed:\n{result.stderr}")
        sys.exit(1)

    os.chmod(binary, 0o755)
    print(f"  Binary -> {binary}")

    # Configure hooks in Claude settings
    configure_hooks()

    print()
    print("Claude Observer installed!")
    print()
    print(f"  Run:  {binary}")
    print("  Tip:  Add to Login Items (System Settings > General > Login Items)")
    print("        for auto-start on login.")
    print()
    print("  The status bar crab will appear when you launch the app.")
    print("  Hooks are active immediately for all Claude Code sessions.")


def configure_hooks():
    hook_script = os.path.join(OBSERVER_DIR, "hooks", "observer-hook.py")
    hook_cmd = f"python3 {hook_script}"

    hook = {"type": "command", "command": hook_cmd}
    hook_with_timeout = {"type": "command", "command": hook_cmd, "timeout": 86400}

    # Events that use matchers need "matcher": "*" to match all tools/notifications
    events = {
        "SessionStart":     {"hooks": [hook]},
        "SessionEnd":       {"hooks": [hook]},
        "UserPromptSubmit": {"hooks": [hook]},
        "Stop":             {"hooks": [hook]},
        "StopFailure":      {"hooks": [hook]},
        "PreCompact":       {"hooks": [hook]},
        "SubagentStart":    {"hooks": [hook]},
        "SubagentStop":     {"hooks": [hook]},
        "PreToolUse":       {"matcher": "*", "hooks": [hook]},
        "PostToolUse":      {"matcher": "*", "hooks": [hook]},
        "Notification":     {"matcher": "*", "hooks": [hook]},
        "PermissionRequest": {"matcher": "*", "hooks": [hook_with_timeout]},
    }

    # Read existing settings
    settings = {}
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE) as f:
            settings = json.load(f)

    if "hooks" not in settings:
        settings["hooks"] = {}

    added = []
    for event, hook_entry in events.items():
        if event not in settings["hooks"]:
            settings["hooks"][event] = []

        # Check if our hook is already installed
        already = False
        for entry in settings["hooks"][event]:
            for h in entry.get("hooks", []):
                if "observer-hook.py" in h.get("command", ""):
                    already = True
                    break

        if not already:
            settings["hooks"][event].append(hook_entry)
            added.append(event)

    # Write back
    with open(SETTINGS_FILE, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")

    if added:
        print(f"  Hooks added for: {', '.join(added)}")
    else:
        print("  Hooks already configured.")


if __name__ == "__main__":
    main()
