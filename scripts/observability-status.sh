#!/bin/bash
# Check observability status

STATE_FILE=".claude/.observability-state"

if [ ! -d ".claude" ]; then
    echo "Error: .claude directory not found. Are you in your project root?"
    exit 1
fi

echo "=== Observability Status ==="

# Check state file
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE" | tr -d '[:space:]')
    if [ "$STATE" = "enabled" ]; then
        echo "Event Streaming: ✅ ENABLED"
    elif [ "$STATE" = "disabled" ]; then
        echo "Event Streaming: 🔕 DISABLED"
    else
        echo "Event Streaming: ⚠️  UNKNOWN (invalid state: $STATE)"
    fi
else
    echo "Event Streaming: ✅ ENABLED (default - no state file)"
fi

# Check if observability server is running
if curl -s http://localhost:4000/events/recent?limit=1 > /dev/null 2>&1; then
    echo "Server Status: ✅ RUNNING (http://localhost:4000)"
else
    echo "Server Status: ❌ NOT RUNNING"
    echo "  Start with: cd /path/to/multi-agent-workflow && ./scripts/start-system.sh"
fi

echo ""
echo "Commands:"
echo "  Enable:  ./scripts/enable-observability.sh"
echo "  Disable: ./scripts/disable-observability.sh"
