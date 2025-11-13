#!/bin/bash
# Enable observability event streaming

STATE_FILE=".claude/.observability-state"

if [ ! -d ".claude" ]; then
    mkdir -p ".claude"
    echo "Created .claude directory"
fi

echo "enabled" > "$STATE_FILE"
echo "✅ Observability enabled (no restart required)"
echo "Events will be sent to observability server"
