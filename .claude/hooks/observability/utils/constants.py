#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "python-dotenv",
# ]
# ///

"""
Constants for Claude Code Hooks.
"""

import os
import json
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None  # dotenv is optional


def get_central_env_path():
    """
    Get the path to the central .env file in multi-agent-workflow repo.

    Strategy:
    1. Check if .observability-config exists (integrated project)
    2. If not, use sentinel detection (running in multi-agent-workflow itself)

    Returns:
        Path object to central .env file, or None if not found
    """
    cwd = Path.cwd()

    # Try loading .observability-config (for integrated projects)
    config_file = cwd / '.claude' / '.observability-config'

    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                multi_agent_workflow_path = config.get('MULTI_AGENT_WORKFLOW_PATH')
                if multi_agent_workflow_path:
                    central_env_path = Path(multi_agent_workflow_path) / '.env'
                    if central_env_path.exists():
                        return central_env_path
        except Exception:
            pass

    # Sentinel detection: Check if we're running in multi-agent-workflow itself
    sentinel_file = cwd / 'scripts' / 'observability-setup.sh'
    if sentinel_file.exists():
        local_env_path = cwd / '.env'
        if local_env_path.exists():
            return local_env_path

    return None


def load_central_env():
    """
    Load environment variables from the central .env file.
    Silently fails if dotenv not available or path not found.
    """
    if not load_dotenv:
        return  # dotenv not installed

    central_env_path = get_central_env_path()
    if central_env_path:
        try:
            load_dotenv(central_env_path, override=True)
        except Exception:
            pass  # Fail silently


# Base directory for all logs
# Default is 'logs' in the current working directory
LOG_BASE_DIR = os.environ.get("CLAUDE_HOOKS_LOG_DIR", "logs")

def get_session_log_dir(session_id: str) -> Path:
    """
    Get the log directory for a specific session.
    
    Args:
        session_id: The Claude session ID
        
    Returns:
        Path object for the session's log directory
    """
    return Path(LOG_BASE_DIR) / session_id

def ensure_session_log_dir(session_id: str) -> Path:
    """
    Ensure the log directory for a session exists.
    
    Args:
        session_id: The Claude session ID
        
    Returns:
        Path object for the session's log directory
    """
    log_dir = get_session_log_dir(session_id)
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir