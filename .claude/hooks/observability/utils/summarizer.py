#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "anthropic",
#     "openai",
#     "python-dotenv",
# ]
# ///

import json
from typing import Optional, Dict, Any, Tuple
from .llm.anth import prompt_llm as prompt_llm_anthropic
from .llm.oai import prompt_llm as prompt_llm_openai


def generate_event_summary(event_data: Dict[str, Any]) -> Tuple[Optional[str], Optional[str]]:
    """
    Generate a concise one-sentence summary of a hook event for engineers.

    Args:
        event_data: The hook event data containing event_type, payload, etc.

    Returns:
        Tuple[Optional[str], Optional[str]]: (summary, failure_message)
        - summary: The generated summary, or None if generation fails
        - failure_message: Error message if key failed, or None if success/not-set
    """
    event_type = event_data.get("hook_event_type", "Unknown")
    payload = event_data.get("payload", {})

    # Convert payload to string representation
    payload_str = json.dumps(payload, indent=2)
    if len(payload_str) > 1000:
        payload_str = payload_str[:1000] + "..."

    prompt = f"""Generate a one-sentence summary of this Claude Code hook event payload for an engineer monitoring the system.

Event Type: {event_type}
Payload:
{payload_str}

Requirements:
- ONE sentence only (no period at the end)
- Focus on the key action or information in the payload
- Be specific and technical
- Keep under 15 words
- Use present tense
- No quotes or formatting
- Return ONLY the summary text

Examples:
- Reads configuration file from project root
- Executes npm install to update dependencies
- Searches web for React documentation
- Edits database schema to add user table
- Agent responds with implementation plan

Generate the summary based on the payload:"""

    import os

    # Try Anthropic first
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    openai_key = os.getenv("OPENAI_API_KEY")

    summary = None
    failure_message = None

    if anthropic_key:
        summary = prompt_llm_anthropic(prompt)
        if not summary:
            # Anthropic key is set but failed
            if openai_key:
                # Try OpenAI fallback
                summary = prompt_llm_openai(prompt)
                if not summary:
                    # Both failed
                    failure_message = "ANTHROPIC_API_KEY and OPENAI_API_KEY both failed for summaries. Remove or replace these keys in your .env file."
                # If OpenAI works, no failure message (silent fallback success)
            else:
                # Only Anthropic was set and it failed
                failure_message = "ANTHROPIC_API_KEY failed for summaries. Remove or replace the key in your .env file to stop this warning."
    elif openai_key:
        # No Anthropic key, try OpenAI
        summary = prompt_llm_openai(prompt)
        if not summary:
            # OpenAI key is set but failed
            failure_message = "OPENAI_API_KEY failed for summaries. Remove or replace the key in your .env file to stop this warning."
    # else: Neither key set, no summary, no failure message

    # Clean up the response if we got one
    if summary:
        summary = summary.strip().strip('"').strip("'").strip(".")
        # Take only the first line if multiple
        summary = summary.split("\n")[0].strip()
        # Ensure it's not too long
        if len(summary) > 100:
            summary = summary[:97] + "..."

    return summary, failure_message
