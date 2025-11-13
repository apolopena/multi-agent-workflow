#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "anthropic",
#     "openai",
#     "python-dotenv",
# ]
# ///

"""
Multi-Agent Observability Hook Script
Sends Claude Code hook events to the observability server.
"""

import json
import sys
import os
import argparse
import urllib.request
import urllib.error
import subprocess
from datetime import datetime
from pathlib import Path
from utils.summarizer import generate_event_summary
from utils.model_extractor import get_model_from_transcript
from utils.constants import get_project_root

# Check if observability is enabled via state file
STATE_FILE = get_project_root() / '.claude' / '.observability-state'
if STATE_FILE.exists():
    state = STATE_FILE.read_text().strip().lower()
    if state != 'enabled':
        # Observability is disabled, exit silently
        sys.exit(0)
# If state file doesn't exist, default to enabled (backwards compatible)

# Cache for config to avoid repeated file reads
_CONFIG_CACHE = None

def load_observability_config():
    """Load configuration from .observability-config file.

    Returns dict with SERVER_URL or None if config doesn't exist.
    Gracefully handles missing/invalid config by returning None.
    Uses caching to avoid repeated file reads (called on every hook event).
    """
    global _CONFIG_CACHE

    # Return cached config if already loaded
    if _CONFIG_CACHE is not None:
        return _CONFIG_CACHE

    try:
        config_file = get_project_root() / '.claude' / '.observability-config'
        if config_file.exists():
            with open(config_file, 'r') as f:
                config = json.load(f)
                # Validate that required keys exist
                if 'SERVER_URL' in config:
                    _CONFIG_CACHE = config
                    return config
        _CONFIG_CACHE = {}  # Cache empty dict to indicate "no config"
        return None
    except Exception as e:
        # Silently fail and use defaults
        print(f"Warning: Could not load observability config: {e}", file=sys.stderr)
        _CONFIG_CACHE = {}  # Cache empty dict to prevent repeated failures
        return None

def get_server_settings(base_url='http://localhost:4000'):
    """Get current settings from the server."""
    try:
        req = urllib.request.Request(
            f'{base_url}/settings',
            headers={'User-Agent': 'Claude-Code-Hook/1.0'}
        )

        with urllib.request.urlopen(req, timeout=2) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8'))
            return None
    except Exception:
        # If we can't get settings, assume default behavior
        return None

def is_server_reachable(base_url='http://localhost:4000'):
    """Check if server is reachable before wasting API quota."""
    try:
        req = urllib.request.Request(
            f'{base_url}/settings',
            headers={'User-Agent': 'Claude-Code-Hook/1.0'}
        )
        with urllib.request.urlopen(req, timeout=2) as response:
            return response.status == 200
    except Exception:
        return False

def trigger_tts_warning(message):
    """Trigger TTS warning for API key failures."""
    try:
        script_dir = Path(__file__).parent
        tts_dir = script_dir / "utils" / "tts"

        # Try OpenAI TTS first (most likely to work)
        if os.getenv('OPENAI_API_KEY'):
            tts_script = tts_dir / "openai_tts.py"
            if tts_script.exists():
                result = subprocess.run(
                    ["uv", "run", str(tts_script), message],
                    capture_output=True,
                    timeout=10
                )
                # Only return if TTS succeeded
                if result.returncode == 0:
                    return

        # Fallback to pyttsx3 (local, no API needed)
        pyttsx3_script = tts_dir / "pyttsx3_tts.py"
        if pyttsx3_script.exists():
            subprocess.run(
                ["uv", "run", str(pyttsx3_script), message],
                capture_output=True,
                timeout=10
            )
    except:
        pass  # Fail silently if TTS unavailable

def send_event_to_server(event_data, server_url='http://localhost:4000/events'):
    """Send event data to the observability server."""
    try:
        # Prepare the request
        req = urllib.request.Request(
            server_url,
            data=json.dumps(event_data).encode('utf-8'),
            headers={
                'Content-Type': 'application/json',
                'User-Agent': 'Claude-Code-Hook/1.0'
            }
        )

        # Send the request
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                return True
            else:
                print(f"Server returned status: {response.status}", file=sys.stderr)
                return False

    except urllib.error.URLError as e:
        print(f"Failed to send event: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return False

def main():
    # Load configuration
    config = load_observability_config()
    default_server_url = 'http://localhost:4000/events'
    if config and 'SERVER_URL' in config:
        # Use SERVER_URL from config and append /events endpoint
        default_server_url = f"{config['SERVER_URL']}/events"

    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Send Claude Code hook events to observability server')
    parser.add_argument('--source-app', help='Source application name (optional, auto-detected from config if not provided)')
    parser.add_argument('--event-type', required=True, help='Hook event type (PreToolUse, PostToolUse, etc.)')
    parser.add_argument('--server-url', default=default_server_url, help='Server URL')
    parser.add_argument('--add-chat', action='store_true', help='Include chat transcript if available')
    parser.add_argument('--summarize', action='store_true', help='Generate AI summary of the event')

    args = parser.parse_args()

    # Determine source_app: CLI arg > config file > project root name
    source_app = args.source_app
    if not source_app:
        # Try to get from config
        if config and 'PROJECT_NAME' in config:
            source_app = config['PROJECT_NAME']
        else:
            # Fallback to project root directory name
            source_app = get_project_root().name
            print(f"Warning: PROJECT_NAME not in config, using project root name: {source_app}", file=sys.stderr)
    
    try:
        # Read hook data from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Extract model name from transcript (with caching)
    session_id = input_data.get('session_id', 'unknown')
    transcript_path = input_data.get('transcript_path', '')
    model_name = ''
    if transcript_path:
        model_name = get_model_from_transcript(session_id, transcript_path)

    # Prepare event data for server
    event_data = {
        'source_app': source_app,
        'session_id': session_id,
        'hook_event_type': args.event_type,
        'payload': input_data,
        'timestamp': int(datetime.now().timestamp() * 1000),
        'model_name': model_name
    }
    
    # Handle --add-chat option
    if args.add_chat and 'transcript_path' in input_data:
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
                
                # Add chat to event data
                event_data['chat'] = chat_data
            except Exception as e:
                print(f"Failed to read transcript: {e}", file=sys.stderr)
    
    # Check server settings to determine if we should generate summary
    should_generate_summary = False
    if args.summarize:
        # Get settings from server
        base_url = args.server_url.rsplit('/', 1)[0]  # Remove /events endpoint

        # Check if server is reachable before wasting API quota
        if is_server_reachable(base_url):
            settings = get_server_settings(base_url)

            if settings and settings.get('summaryMode') == 'realtime':
                should_generate_summary = True
            # If settings unavailable, respect the --summarize flag for backward compatibility
            elif settings is None:
                should_generate_summary = True
        # else: Server unreachable, don't waste API quota on summaries

    # Generate summary if enabled in settings
    if should_generate_summary:
        summary, failure_message = generate_event_summary(event_data)
        if summary:
            event_data['summary'] = summary
        # Trigger TTS warning if API key failed
        if failure_message:
            trigger_tts_warning(failure_message)
        # Continue even if summary generation fails
    
    # Send to server
    success = send_event_to_server(event_data, args.server_url)
    
    # Always exit with 0 to not block Claude Code operations
    sys.exit(0)

if __name__ == '__main__':
    main()