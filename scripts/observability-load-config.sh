#!/bin/bash
# Reusable script to load .observability-config
# Source this file from other scripts to get config variables

# Find .claude directory (search up from current directory)
find_claude_dir() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/.claude/.observability-config" ]; then
            echo "$dir/.claude"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Load configuration
CLAUDE_DIR=$(find_claude_dir)
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
    echo "Please update .claude/.observability-config or re-run setup-observability.sh" >&2
    exit 1
fi

# Export variables for use by calling script
export MULTI_AGENT_WORKFLOW_PATH
export SERVER_URL
export CLIENT_URL
export CLAUDE_DIR
