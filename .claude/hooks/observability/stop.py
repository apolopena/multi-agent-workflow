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
import random
import subprocess
from pathlib import Path
from datetime import datetime
from utils.constants import ensure_session_log_dir, load_central_env, get_project_root

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


def get_completion_messages():
    """Return list of friendly completion messages."""
    return [
        "Work complete!",
        "All done!",
        "Task finished!",
        "Job complete!",
        "Ready for next task!",
    ]


def get_tts_script_path():
    """
    Determine which TTS script to use based on available API keys.
    Priority order: ElevenLabs > OpenAI > pyttsx3
    """
    # Get current script directory and construct utils/tts path
    script_dir = Path(__file__).parent
    tts_dir = script_dir / "utils" / "tts"

    # Check for ElevenLabs API key (highest priority)
    if os.getenv("ELEVENLABS_API_KEY"):
        elevenlabs_script = tts_dir / "elevenlabs_tts.py"
        if elevenlabs_script.exists():
            return str(elevenlabs_script)

    # Check for OpenAI API key (second priority)
    if os.getenv("OPENAI_API_KEY"):
        openai_script = tts_dir / "openai_tts.py"
        if openai_script.exists():
            return str(openai_script)

    # Fall back to pyttsx3 (no API key required)
    pyttsx3_script = tts_dir / "pyttsx3_tts.py"
    if pyttsx3_script.exists():
        return str(pyttsx3_script)

    return None


def get_llm_completion_message():
    """
    Generate completion message using available LLM services.
    Priority order: Anthropic > OpenAI > fallback to random message

    Returns:
        Tuple[str, Optional[str]]: (message, failure_warning)
        - message: The completion message to speak
        - failure_warning: Warning message if API keys failed, or None
    """
    # Get current script directory and construct utils/llm path
    script_dir = Path(__file__).parent
    llm_dir = script_dir / "utils" / "llm"

    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    openai_key = os.getenv("OPENAI_API_KEY")

    anthropic_failed = False
    openai_failed = False

    # Try Anthropic first
    if anthropic_key:
        anth_script = llm_dir / "anth.py"
        if anth_script.exists():
            try:
                result = subprocess.run(
                    ["uv", "run", str(anth_script), "--completion"],
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                if result.returncode == 0 and result.stdout.strip():
                    output = result.stdout.strip()
                    # Check if output is an error message
                    if not output.startswith("Error"):
                        return output, None
                # If we get here, Anthropic failed
                anthropic_failed = True
            except (subprocess.TimeoutExpired, subprocess.SubprocessError):
                anthropic_failed = True

    # Try OpenAI second
    if openai_key:
        oai_script = llm_dir / "oai.py"
        if oai_script.exists():
            try:
                result = subprocess.run(
                    ["uv", "run", str(oai_script), "--completion"],
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                if result.returncode == 0 and result.stdout.strip():
                    output = result.stdout.strip()
                    # Check if output is an error message
                    if not output.startswith("Error"):
                        # Determine warning message
                        warning = None
                        if anthropic_failed:
                            # Anthropic failed but OpenAI worked (silent - no warning)
                            pass
                        return output, warning
                # If we get here, OpenAI failed
                openai_failed = True
            except (subprocess.TimeoutExpired, subprocess.SubprocessError):
                openai_failed = True

    # Both failed or neither set - use fallback
    messages = get_completion_messages()
    message = random.choice(messages)

    # Generate warning if keys were set but failed
    warning = None
    if anthropic_failed and openai_failed:
        warning = "ANTHROPIC_API_KEY and OPENAI_API_KEY both failed for completion messages. Remove or replace these keys in your .env file."
    elif anthropic_failed and not openai_key:
        warning = "ANTHROPIC_API_KEY failed for completion messages. Remove or replace the key in your .env file to stop this warning."
    elif openai_failed and not anthropic_key:
        warning = "OPENAI_API_KEY failed for completion messages. Remove or replace the key in your .env file to stop this warning."

    return message, warning


def announce_completion():
    """Announce completion using the best available TTS service with fallback."""
    try:
        script_dir = Path(__file__).parent
        tts_dir = script_dir / "utils" / "tts"

        # Get completion message and any failure warning
        completion_message, failure_warning = get_llm_completion_message()

        # Try TTS methods in priority order with fallback
        tts_success = False

        # Try ElevenLabs first
        if os.getenv("ELEVENLABS_API_KEY"):
            elevenlabs_script = tts_dir / "elevenlabs_tts.py"
            if elevenlabs_script.exists():
                try:
                    if failure_warning:
                        result = subprocess.run(
                            ["uv", "run", str(elevenlabs_script), failure_warning],
                            capture_output=True,
                            timeout=10,
                        )
                        if result.returncode != 0:
                            raise Exception("ElevenLabs TTS failed")

                    result = subprocess.run(
                        ["uv", "run", str(elevenlabs_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                    if result.returncode == 0:
                        tts_success = True
                except:
                    pass  # Try next method

        # Try OpenAI if ElevenLabs didn't work
        if not tts_success and os.getenv("OPENAI_API_KEY"):
            openai_script = tts_dir / "openai_tts.py"
            if openai_script.exists():
                try:
                    if failure_warning:
                        result = subprocess.run(
                            ["uv", "run", str(openai_script), failure_warning],
                            capture_output=True,
                            timeout=10,
                        )
                        if result.returncode != 0:
                            raise Exception("OpenAI TTS failed")

                    result = subprocess.run(
                        ["uv", "run", str(openai_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                    if result.returncode == 0:
                        tts_success = True
                except:
                    pass  # Try next method

        # Fallback to pyttsx3 (always available, no API key needed)
        if not tts_success:
            pyttsx3_script = tts_dir / "pyttsx3_tts.py"
            if pyttsx3_script.exists():
                try:
                    if failure_warning:
                        subprocess.run(
                            ["uv", "run", str(pyttsx3_script), failure_warning],
                            capture_output=True,
                            timeout=10,
                        )

                    subprocess.run(
                        ["uv", "run", str(pyttsx3_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                except:
                    pass  # Fail silently

    except Exception:
        # Fail silently for any other errors
        pass


def main():
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--chat", action="store_true", help="Copy transcript to chat.json"
        )
        args = parser.parse_args()

        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        # Extract required fields
        session_id = input_data.get("session_id", "")
        stop_hook_active = input_data.get("stop_hook_active", False)

        # Ensure session log directory exists
        log_dir = ensure_session_log_dir(session_id)
        log_path = log_dir / "stop.json"

        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, "r") as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []

        # Append new data
        log_data.append(input_data)

        # Write back to file with formatting
        with open(log_path, "w") as f:
            json.dump(log_data, f, indent=2)

        # Handle --chat switch
        if args.chat and "transcript_path" in input_data:
            transcript_path = input_data["transcript_path"]
            if os.path.exists(transcript_path):
                # Read .jsonl file and convert to JSON array
                chat_data = []
                try:
                    with open(transcript_path, "r") as f:
                        for line in f:
                            line = line.strip()
                            if line:
                                try:
                                    chat_data.append(json.loads(line))
                                except json.JSONDecodeError:
                                    pass  # Skip invalid lines

                    # Write to logs/chat.json
                    chat_file = os.path.join(log_dir, "chat.json")
                    with open(chat_file, "w") as f:
                        json.dump(chat_data, f, indent=2)
                except Exception:
                    pass  # Fail silently

        # Announce completion via TTS
        announce_completion()

        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == "__main__":
    main()
