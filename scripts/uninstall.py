#!/usr/bin/env python3
"""Uninstall Claude Observer: remove hooks, binary, and state."""

import json
import os
import shutil
import subprocess

HOME = os.path.expanduser("~")
OBSERVER_DIR = os.path.join(HOME, ".claude-observer")
SETTINGS_FILE = os.path.join(HOME, ".claude", "settings.json")


def main():
    print("Uninstalling Claude Observer...")

    # Kill running instance
    subprocess.run(["pkill", "-x", "claude-observer"], capture_output=True)

    # Remove hooks from settings
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE) as f:
            settings = json.load(f)

        if "hooks" in settings:
            for event in list(settings["hooks"].keys()):
                settings["hooks"][event] = [
                    entry
                    for entry in settings["hooks"][event]
                    if not any(
                        "observer-hook.py" in h.get("command", "")
                        for h in entry.get("hooks", [])
                    )
                ]
                if not settings["hooks"][event]:
                    del settings["hooks"][event]

        with open(SETTINGS_FILE, "w") as f:
            json.dump(settings, f, indent=2)
            f.write("\n")

        print("  Removed hooks from settings.")

    # Remove observer directory
    if os.path.exists(OBSERVER_DIR):
        shutil.rmtree(OBSERVER_DIR)
        print(f"  Removed {OBSERVER_DIR}")

    print("Claude Observer uninstalled.")


if __name__ == "__main__":
    main()
