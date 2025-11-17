#!/bin/bash
# Auto-generated wrapper by observability-setup.sh
# Calls observability-stop.sh from multi-agent-workflow

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.claude/.observability-config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Observability config not found: $CONFIG_FILE" >&2
    echo "Run observability-setup.sh to reconfigure." >&2
    exit 1
fi

# Parse config (requires jq)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

MULTI_AGENT_WORKFLOW_PATH=$(jq -r '.MULTI_AGENT_WORKFLOW_PATH' "$CONFIG_FILE")

# Validate path exists
if [ ! -d "$MULTI_AGENT_WORKFLOW_PATH" ]; then
    echo "Error: Multi-agent-workflow not found: $MULTI_AGENT_WORKFLOW_PATH" >&2
    echo "The observability repo may have been moved." >&2
    echo "Update $CONFIG_FILE or re-run observability-setup.sh" >&2
    exit 1
fi

# Check target script exists
TARGET_SCRIPT="$MULTI_AGENT_WORKFLOW_PATH/scripts/observability-stop.sh"
if [ ! -f "$TARGET_SCRIPT" ]; then
    echo "Error: Script not found: $TARGET_SCRIPT" >&2
    echo "The multi-agent-workflow installation may be incomplete." >&2
    exit 1
fi

# Execute the real script
exec "$TARGET_SCRIPT" "$@"
