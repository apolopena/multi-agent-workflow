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
from utils.constants import ensure_session_log_dir, load_central_env

# Load central environment variables
load_central_env()


def get_tts_script_path():
    """
    Determine which TTS script to use based on available API keys.
    Priority order: ElevenLabs > OpenAI > pyttsx3
    """
    # Get current script directory and construct utils/tts path
    script_dir = Path(__file__).parent
    tts_dir = script_dir / "utils" / "tts"
    
    # Check for ElevenLabs API key (highest priority)
    if os.getenv('ELEVENLABS_API_KEY'):
        elevenlabs_script = tts_dir / "elevenlabs_tts.py"
        if elevenlabs_script.exists():
            return str(elevenlabs_script)
    
    # Check for OpenAI API key (second priority)
    if os.getenv('OPENAI_API_KEY'):
        openai_script = tts_dir / "openai_tts.py"
        if openai_script.exists():
            return str(openai_script)
    
    # Fall back to pyttsx3 (no API key required)
    pyttsx3_script = tts_dir / "pyttsx3_tts.py"
    if pyttsx3_script.exists():
        return str(pyttsx3_script)
    
    return None


def announce_subagent_completion():
    """Announce subagent completion using the best available TTS service with fallback."""
    try:
        script_dir = Path(__file__).parent
        tts_dir = script_dir / "utils" / "tts"
        completion_message = "Subagent Complete"

        # Try TTS methods in priority order with fallback
        tts_success = False

        # Try ElevenLabs first
        if os.getenv("ELEVENLABS_API_KEY"):
            elevenlabs_script = tts_dir / "elevenlabs_tts.py"
            if elevenlabs_script.exists():
                try:
                    result = subprocess.run(
                        ["uv", "run", str(elevenlabs_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                    if result.returncode == 0:
                        tts_success = True
                except:
                    pass

        # Try OpenAI if ElevenLabs didn't work
        if not tts_success and os.getenv("OPENAI_API_KEY"):
            openai_script = tts_dir / "openai_tts.py"
            if openai_script.exists():
                try:
                    result = subprocess.run(
                        ["uv", "run", str(openai_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                    if result.returncode == 0:
                        tts_success = True
                except:
                    pass

        # Fallback to pyttsx3
        if not tts_success:
            pyttsx3_script = tts_dir / "pyttsx3_tts.py"
            if pyttsx3_script.exists():
                try:
                    subprocess.run(
                        ["uv", "run", str(pyttsx3_script), completion_message],
                        capture_output=True,
                        timeout=10,
                    )
                except:
                    pass

    except Exception:
        pass


def main():
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument('--chat', action='store_true', help='Copy transcript to chat.json')
        args = parser.parse_args()
        
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        # Extract required fields
        session_id = input_data.get("session_id", "")
        stop_hook_active = input_data.get("stop_hook_active", False)

        # Ensure session log directory exists
        log_dir = ensure_session_log_dir(session_id)
        log_path = log_dir / "subagent_stop.json"

        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_path, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        # Handle --chat switch (same as stop.py)
        if args.chat and 'transcript_path' in input_data:
            transcript_path = input_data['transcript_path']
            if os.path.exists(transcript_path):
                # Read .jsonl file and convert to JSON array
                chat_data = []
                try:
                    with open(transcript_path, 'r') as f:
                        for line in f:
                            line = line.strip()
                            if line:
                                try:
                                    chat_data.append(json.loads(line))
                                except json.JSONDecodeError:
                                    pass  # Skip invalid lines
                    
                    # Write to logs/chat.json
                    chat_file = os.path.join(log_dir, 'chat.json')
                    with open(chat_file, 'w') as f:
                        json.dump(chat_data, f, indent=2)
                except Exception:
                    pass  # Fail silently

        # Announce subagent completion via TTS
        announce_subagent_completion()

        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == "__main__":
    main()