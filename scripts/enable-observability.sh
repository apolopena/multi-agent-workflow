#!/bin/bash
# Enable observability event streaming

STATE_FILE=".claude/.observability-state"

if [ ! -d ".claude" ]; then
    echo "Error: .claude directory not found. Are you in your project root?"
    exit 1
fi

echo "enabled" > "$STATE_FILE"
echo "✅ Observability enabled (no restart required)"
echo "Events will be sent to observability server"
