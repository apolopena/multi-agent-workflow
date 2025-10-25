#!/bin/bash
# Disable observability event streaming

STATE_FILE=".claude/.observability-state"

if [ ! -d ".claude" ]; then
    echo "Error: .claude directory not found. Are you in your project root?"
    exit 1
fi

echo "disabled" > "$STATE_FILE"
echo "🔕 Observability disabled (no restart required)"
echo "Events will not be sent to observability server"
echo "Local logging and validation hooks will still run"
