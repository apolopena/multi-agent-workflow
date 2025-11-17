#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import argparse
import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from utils.constants import load_central_env, get_project_root

# Load central environment variables
load_central_env()

# Check if observability is enabled via state file
STATE_FILE = get_project_root() / '.claude' / '.observability-state'
if STATE_FILE.exists():
    state = STATE_FILE.read_text().strip().lower()
    if state != 'enabled':
        # Observability is disabled, exit silently
        sys.exit(0)
# If state file doesn't exist, default to enabled (backwards compatible)


# Removed: Aggregate logging function (unused)


# Removed: Aggregate session statistics function (unused)


def main():
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument('--announce', action='store_true',
                          help='Announce session end via TTS')
        parser.add_argument('--save-stats', action='store_true',
                          help='Save session statistics')
        args = parser.parse_args()

        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())

        # Extract fields
        session_id = input_data.get('session_id', 'unknown')
        reason = input_data.get('reason', 'other')

        # Removed: Aggregate logging calls (unused)

        # Announce session end if requested
        if args.announce:
            try:
                # Try to use TTS to announce session end
                script_dir = Path(__file__).parent
                tts_script = script_dir / "utils" / "tts" / "pyttsx3_tts.py"

                if tts_script.exists():
                    messages = {
                        "clear": "Session cleared",
                        "logout": "Logging out",
                        "prompt_input_exit": "Session ended",
                        "other": "Session ended"
                    }
                    message = messages.get(reason, "Session ended")

                    subprocess.run(
                        ["uv", "run", str(tts_script), message],
                        capture_output=True,
                        timeout=5
                    )
            except Exception:
                pass

        # Success
        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == '__main__':
    main()
