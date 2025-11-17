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


def get_project_root():
    """
    Get the project root directory (git repository root, not worktree).

    For git worktrees, this returns the MAIN repository root,
    ensuring all worktrees share the same configuration and data.

    Searches upward from current directory using git first, then .claude/ directory.

    Returns:
        Path object to project root, or current working directory if not found
    """
    import subprocess

    current = Path.cwd()

    # Try git first - returns main repo root even for worktrees
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--show-toplevel'],
            capture_output=True,
            text=True,
            cwd=current,
            timeout=2
        )
        if result.returncode == 0:
            git_root = Path(result.stdout.strip())
            if (git_root / '.claude').exists():
                return git_root
    except Exception:
        pass  # Git not available or not in a git repo

    # Fallback: search upward for .claude directory
    for parent in [current] + list(current.parents):
        if (parent / '.claude').exists():
            return parent

    # Final fallback to current directory
    return current


def get_central_env_path():
    """
    Get the path to the central .env file in multi-agent-workflow repo.

    Strategy:
    1. Check if .observability-config exists (integrated project)
    2. If not, use sentinel detection (running in multi-agent-workflow itself)

    Returns:
        Path object to central .env file, or None if not found
    """
    project_root = get_project_root()

    # Try loading .observability-config (for integrated projects)
    config_file = project_root / '.claude' / '.observability-config'

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
    sentinel_file = project_root / 'scripts' / 'observability-setup.sh'
    if sentinel_file.exists():
        local_env_path = project_root / '.env'
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


def get_central_repo_path():
    """
    Get the path to the central multi-agent-workflow repository.

    Strategy:
    1. Find project root (where .claude/ exists)
    2. Check if .observability-config exists (integrated project)
    3. If not, use sentinel detection (running in multi-agent-workflow itself)

    Returns:
        Path object to central repo, or project root if not found
    """
    project_root = get_project_root()

    # Try loading .observability-config (for integrated projects)
    config_file = project_root / '.claude' / '.observability-config'

    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                multi_agent_workflow_path = config.get('MULTI_AGENT_WORKFLOW_PATH')
                if multi_agent_workflow_path:
                    return Path(multi_agent_workflow_path)
        except Exception:
            pass

    # Sentinel detection: Check if we're running in multi-agent-workflow itself
    sentinel_file = project_root / 'scripts' / 'observability-setup.sh'
    if sentinel_file.exists():
        return project_root

    # Fallback to project root
    return project_root


# Base directory for all logs
# Use environment variable override, or default to project root's .claude/data/observability/logs
_project_root = get_project_root()
LOG_BASE_DIR = os.environ.get("CLAUDE_HOOKS_LOG_DIR", str(_project_root / ".claude" / "data" / "observability" / "logs"))

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