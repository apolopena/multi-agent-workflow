# How to Extract and Send Model Name from Claude Code Hooks

This guide explains how to extract the model name from Claude Code transcripts and send it with your hook events, including implementing an efficient caching system.

## Overview

Claude Code hooks receive a `transcript_path` in their stdin, which points to a `.jsonl` file containing the conversation history. The model name is only available in **assistant messages**, not user messages or hook metadata.

## The Problem

- Transcript files can be **very large** (3+ MB with hundreds of thousands of lines)
- Hooks fire **frequently** (dozens to hundreds of times per minute during active coding)
- Reading and parsing the entire transcript on every hook event would cause significant I/O and performance issues
- The model **rarely changes** during a session (only when user runs `/model` command)

## The Solution: File-Based Cache with TTL

We implement a 60-second cache to avoid repeatedly parsing the transcript file.

### Cache Strategy

1. **Cache Location**: `.claude/data/claude-model-cache/{session_id}.json`
   - **Important**: Cache is stored **locally in your project** at `.claude/data/`, NOT globally in `~/.claude/`
   - Uses relative path from `model_extractor.py` file location
   - Each project has its own independent cache
2. **Cache TTL**: 60 seconds (configurable)
3. **Cache Key**: Session ID (unique per Claude Code session)
4. **Cache Structure**:
```json
{
  "model": "claude-haiku-4-5-20251001",
  "timestamp": 1729123456789,
  "ttl": 60
}
```

### Why This Works

- Model changes are rare (only on explicit `/model` command)
- 60-second freshness is acceptable for observability
- Cache is session-specific (different sessions = different cache files)
- Cache is project-local (different projects = independent caches)
- Old caches naturally expire and get overwritten
- Relative path ensures cache works regardless of current working directory

---

## Implementation

### Step 1: Create Model Extractor Utility

Create `.claude/hooks/utils/model_extractor.py`:

```python
"""
Model Extractor Utility
Extracts model name from Claude Code transcript with caching.
"""

import json
import os
import time
from pathlib import Path


def get_model_from_transcript(session_id: str, transcript_path: str, ttl: int = 60) -> str:
    """
    Extract model name from transcript with file-based caching.

    Args:
        session_id: Claude session ID
        transcript_path: Path to the .jsonl transcript file
        ttl: Cache time-to-live in seconds (default: 60)

    Returns:
        Model name string (e.g., "claude-haiku-4-5-20251001") or empty string if not found
    """
    # Set up cache directory relative to this file location
    # __file__ is .claude/hooks/utils/model_extractor.py
    # We want .claude/data/claude-model-cache/
    cache_dir = Path(__file__).parent.parent.parent / "data" / "claude-model-cache"
    cache_dir.mkdir(parents=True, exist_ok=True)

    cache_file = cache_dir / f"{session_id}.json"
    current_time = time.time()

    # Try to read from cache
    if cache_file.exists():
        try:
            with open(cache_file, 'r') as f:
                cache_data = json.load(f)

            # Check if cache is still fresh
            cache_age = current_time - cache_data.get('timestamp', 0)
            if cache_age < ttl:
                return cache_data.get('model', '')
        except (json.JSONDecodeError, IOError):
            # Cache file corrupted or unreadable, will regenerate
            pass

    # Cache miss or stale - extract from transcript
    model_name = extract_model_from_transcript(transcript_path)

    # Save to cache
    try:
        cache_data = {
            'model': model_name,
            'timestamp': current_time,
            'ttl': ttl
        }
        with open(cache_file, 'w') as f:
            json.dump(cache_data, f)
    except IOError:
        # Cache write failed, not critical - continue without cache
        pass

    return model_name


def extract_model_from_transcript(transcript_path: str) -> str:
    """
    Extract model name from transcript by finding most recent assistant message.

    Args:
        transcript_path: Path to the .jsonl transcript file

    Returns:
        Model name string or empty string if not found
    """
    if not os.path.exists(transcript_path):
        return ''

    model_name = ''

    try:
        # Read transcript file
        with open(transcript_path, 'r') as f:
            lines = f.readlines()

        # Iterate in REVERSE to find most recent assistant message with model
        for line in reversed(lines):
            line = line.strip()
            if not line:
                continue

            try:
                entry = json.loads(line)

                # Check if this is an assistant message with a model field
                # Entry structure:
                # {
                #   "type": "assistant",
                #   "message": {
                #     "model": "claude-haiku-4-5-20251001",
                #     "role": "assistant",
                #     "content": [...]
                #   }
                # }
                if (entry.get('type') == 'assistant' and
                    'message' in entry and
                    'model' in entry['message']):
                    model_name = entry['message']['model']
                    break  # Found the most recent one

            except json.JSONDecodeError:
                # Skip invalid JSON lines
                continue

    except IOError:
        # File read error
        return ''

    return model_name
```

### Step 2: Update Your Hook Script

Update your `send_event.py` (or equivalent):

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "anthropic",
#     "python-dotenv",
# ]
# ///

import json
import sys
import os
from datetime import datetime
from utils.model_extractor import get_model_from_transcript


def main():
    # Parse hook input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    # Extract session ID and transcript path
    session_id = input_data.get('session_id', 'unknown')
    transcript_path = input_data.get('transcript_path', '')

    # Extract model name (with caching)
    model_name = ''
    if transcript_path:
        model_name = get_model_from_transcript(session_id, transcript_path)

    # Prepare event data for your observability server
    event_data = {
        'source_app': 'your-app-name',  # Your application identifier
        'session_id': session_id,
        'hook_event_type': 'PreToolUse',  # Or whatever hook type
        'payload': input_data,
        'timestamp': int(datetime.now().timestamp() * 1000),
        'model_name': model_name  # ← The extracted model name
    }

    # Send to your observability server
    send_event_to_server(event_data)

    # Always exit 0 to not block Claude Code
    sys.exit(0)


if __name__ == '__main__':
    main()
```

---

## What Data to Send

Send this JSON structure to your observability server:

```json
{
  "source_app": "your-app-name",
  "session_id": "3a7ccba5-5ef4-4bbd-8073-1006351b010e",
  "hook_event_type": "PreToolUse",
  "payload": {
    "session_id": "3a7ccba5-5ef4-4bbd-8073-1006351b010e",
    "transcript_path": "/Users/.../.claude/projects/.../session.jsonl",
    "cwd": "/path/to/project",
    "hook_event_name": "PreToolUse",
    "tool_name": "Write",
    "tool_input": { ... }
  },
  "timestamp": 1729123456789,
  "model_name": "claude-haiku-4-5-20251001"
}
```

### Key Fields

| Field             | Type   | Required | Description                                           |
| ----------------- | ------ | -------- | ----------------------------------------------------- |
| `source_app`      | string | Yes      | Your application identifier (e.g., "my-agent-system") |
| `session_id`      | string | Yes      | Claude Code session ID                                |
| `hook_event_type` | string | Yes      | Hook event type (PreToolUse, PostToolUse, etc.)       |
| `payload`         | object | Yes      | Original hook input data from stdin                   |
| `timestamp`       | number | Yes      | Unix timestamp in milliseconds                        |
| `model_name`      | string | No       | Model name (empty string if not available)            |

---

## How the Caching Works

### First Hook Event (Cache Miss)

```
1. Hook fires → send_event.py runs
2. Check cache: .claude/data/claude-model-cache/{session_id}.json (in project)
3. Cache file doesn't exist
4. Read transcript file (3+ MB)
5. Parse JSONL line by line in REVERSE
6. Find first (most recent) assistant message with "model" field
7. Extract model: "claude-haiku-4-5-20251001"
8. Write to cache file with timestamp
9. Send event with model_name to server
```

### Subsequent Hook Events (Cache Hit)

```
1. Hook fires → send_event.py runs
2. Check cache: .claude/data/claude-model-cache/{session_id}.json (in project)
3. Cache file exists
4. Read cache (tiny JSON file, < 1 KB)
5. Check timestamp: current_time - cache_timestamp < 60s?
6. Yes → Use cached model name
7. Send event with model_name to server
8. Total time: ~1ms (vs ~50-100ms parsing full transcript)
```

### Cache Expiration (After 60 Seconds)

```
1. Hook fires → send_event.py runs
2. Check cache: .claude/data/claude-model-cache/{session_id}.json (in project)
3. Cache file exists
4. Read cache
5. Check timestamp: current_time - cache_timestamp < 60s?
6. No → Cache is stale (expired)
7. Re-read transcript file
8. Extract latest model name (may have changed if user ran /model)
9. Update cache file with new timestamp
10. Send event with model_name to server
```

---

## When Model Name Is Available

| Hook Event              | Model Available? | Why                          |
| ----------------------- | ---------------- | ---------------------------- |
| `SessionStart`          | ❌ No             | No assistant messages yet    |
| `PreUserMessageSubmit`  | ❌ No             | Before assistant responds    |
| `PostUserMessageSubmit` | ❌ No             | Before assistant responds    |
| `PreToolUse`            | ✅ Yes            | Assistant requested the tool |
| `PostToolUse`           | ✅ Yes            | Same assistant turn          |
| `Stop`                  | ✅ Yes            | Assistant just finished      |
| `SubagentStop`          | ✅ Yes            | Subagent finished            |
| `PreCompact`            | ✅ Yes (usually)  | Assistant has been active    |

**Note**: For hooks that fire before the first assistant message, `model_name` will be an empty string `""`.

---

## Performance Metrics

### Without Caching
- **Transcript file size**: 3.2 MB
- **Parse time**: ~50-100ms per hook
- **Hook frequency**: ~100 events/minute during active coding
- **Total I/O time**: 5-10 seconds/minute of parsing

### With 60-Second Cache
- **Cache file size**: < 1 KB
- **Cache read time**: ~1ms
- **Cache hit rate**: ~99% (model rarely changes)
- **Total I/O time**: ~100ms/minute

**Result**: **50-100x performance improvement**

---

## Testing Your Implementation

### Test 1: Verify Cache Creation

```bash
# Run a hook manually
echo '{"session_id":"test-123","transcript_path":"/path/to/transcript.jsonl"}' | \
  python .claude/hooks/observability/send_event.py

# Check cache was created (in project directory)
cat .claude/data/claude-model-cache/test-123.json
```

Expected output:
```json
{
  "model": "claude-haiku-4-5-20251001",
  "timestamp": 1729123456.789,
  "ttl": 60
}
```

### Test 2: Verify Cache Hit

```bash
# Run the same hook twice quickly
time python .claude/hooks/observability/send_event.py < input.json  # ~50ms (cache miss)
time python .claude/hooks/observability/send_event.py < input.json  # ~1ms (cache hit)
```

### Test 3: Verify Cache Expiration

```bash
# Run hook
python .claude/hooks/observability/send_event.py < input.json

# Wait 61 seconds
sleep 61

# Run again - should re-parse transcript
python .claude/hooks/observability/send_event.py < input.json
```

---

## Troubleshooting

### Model Name Is Always Empty

**Check**:
1. Transcript file exists at the path in `transcript_path`
2. Transcript has at least one assistant message
3. Assistant message has the correct structure with `message.model` field

**Debug**:
```python
# Add logging to extract_model_from_transcript
print(f"Reading transcript: {transcript_path}", file=sys.stderr)
print(f"Found {len(lines)} lines", file=sys.stderr)
print(f"Extracted model: {model_name}", file=sys.stderr)
```

### Cache Not Working

**Check**:
1. Cache directory exists in project: `.claude/data/claude-model-cache/`
2. Cache directory is writable (check project permissions)
3. Session ID is consistent across hook calls

**Debug**:
```python
# Add logging to get_model_from_transcript
print(f"Cache file: {cache_file}", file=sys.stderr)
print(f"Cache exists: {cache_file.exists()}", file=sys.stderr)
print(f"Cache age: {cache_age}s (TTL: {ttl}s)", file=sys.stderr)
```

### Hooks Too Slow

**Check**:
1. Cache is being used (see debug above)
2. TTL is set appropriately (60s is recommended)
3. Transcript file is not extremely large (>10 MB)

**Optimize**:
- Increase TTL to 120s if model changes are very rare
- Use a faster storage location (e.g., `/tmp/` instead of `.claude/data/`)
- Consider in-memory caching if running a persistent service

---

## Advanced: In-Memory Cache for Persistent Services

If you're running a persistent observability service (not just a script), use in-memory caching:

```python
import time
from typing import Dict, Tuple

# Global in-memory cache: session_id -> (model_name, timestamp)
_model_cache: Dict[str, Tuple[str, float]] = {}
_cache_ttl = 60


def get_model_from_transcript_memory(session_id: str, transcript_path: str) -> str:
    """In-memory cache version for persistent services."""
    current_time = time.time()

    # Check in-memory cache
    if session_id in _model_cache:
        model_name, timestamp = _model_cache[session_id]
        if current_time - timestamp < _cache_ttl:
            return model_name

    # Cache miss - extract from transcript
    model_name = extract_model_from_transcript(transcript_path)

    # Update in-memory cache
    _model_cache[session_id] = (model_name, current_time)

    return model_name
```

---

## Summary

1. **Extract model from transcript** - Read `.jsonl` file, find most recent assistant message
2. **Implement 60-second cache** - Store in `.claude/data/claude-model-cache/{session_id}.json` (in project)
3. **Send model_name with events** - Include in your event payload to observability server
4. **Handle empty model** - Some hooks fire before first assistant message

This approach gives you model visibility with minimal performance impact!
