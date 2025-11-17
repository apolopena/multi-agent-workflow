#!/bin/bash
# Load observability configuration
# Source this file to get MULTI_AGENT_WORKFLOW_PATH and other config vars

# Find .claude directory (search up from current directory or script location)
find_claude_dir() {
    local start_dir="${1:-$PWD}"
    local dir="$start_dir"

    while [ "$dir" != "/" ]; do
        if [ -f "$dir/.claude/.observability-config" ]; then
            echo "$dir/.claude"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Try from current directory first, then from script location
CLAUDE_DIR=$(find_claude_dir "$PWD")
if [ -z "$CLAUDE_DIR" ]; then
    # Try from script's directory
    SCRIPT_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CLAUDE_DIR=$(find_claude_dir "$SCRIPT_LOCATION")
fi

if [ -z "$CLAUDE_DIR" ]; then
    echo "Error: Could not find .claude/.observability-config" >&2
    echo "Have you run setup-observability.sh?" >&2
    exit 1
fi

CONFIG_FILE="$CLAUDE_DIR/.observability-config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Observability config not found: $CONFIG_FILE" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Load config variables
MULTI_AGENT_WORKFLOW_PATH=$(jq -r '.MULTI_AGENT_WORKFLOW_PATH' "$CONFIG_FILE")
SERVER_URL=$(jq -r '.SERVER_URL' "$CONFIG_FILE")
CLIENT_URL=$(jq -r '.CLIENT_URL' "$CONFIG_FILE")

# Validate multi-agent-workflow path exists
if [ ! -d "$MULTI_AGENT_WORKFLOW_PATH" ]; then
    echo "Error: Multi-agent-workflow directory not found: $MULTI_AGENT_WORKFLOW_PATH" >&2
    echo "" >&2
    echo "The observability system repository has been moved or deleted." >&2
    echo "Please update $CONFIG_FILE or re-run setup-observability.sh" >&2
    exit 1
fi

# Export variables for use by calling script
export MULTI_AGENT_WORKFLOW_PATH
export SERVER_URL
export CLIENT_URL
export CLAUDE_DIR
