#!/bin/bash
# Disable observability event streaming

STATE_FILE=".claude/.observability-state"

if [ ! -d ".claude" ]; then
    mkdir -p ".claude"
    echo "Created .claude directory"
fi

echo "disabled" > "$STATE_FILE"
echo "🔕 Observability disabled (no restart required)"
echo "Events will not be sent to observability server"
echo "Local logging and validation hooks will still run"
