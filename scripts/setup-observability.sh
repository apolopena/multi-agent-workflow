#!/bin/bash
# Setup observability hooks for an existing project

# Get project name from git repo or use provided argument
if [ -z "$1" ]; then
    # Try to get git repo name
    if git rev-parse --git-dir > /dev/null 2>&1; then
        PROJECT_NAME=$(basename -s .git $(git config --get remote.origin.url) 2>/dev/null)
        if [ -z "$PROJECT_NAME" ]; then
            # Fallback to directory name if no remote
            PROJECT_NAME=$(basename "$PWD")
        fi
        echo "Using git repo name: $PROJECT_NAME"
    else
        echo "Error: Not a git repository and no PROJECT_NAME provided"
        echo "Usage: $0 [PROJECT_NAME]"
        echo "Example: $0 peachy-devops"
        exit 1
    fi
else
    PROJECT_NAME="$1"
fi

SETTINGS_FILE=".claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Error: $SETTINGS_FILE not found. Are you in your project root?"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with: sudo apt install jq"
    exit 1
fi

# Check if hooks already exist and warn
if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo "⚠️  WARNING: Existing hooks found in $SETTINGS_FILE"
    echo "This script will OVERWRITE your existing hooks configuration."
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Backup existing settings
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
echo "Created backup: $SETTINGS_FILE.backup"

# Read the hooks template from multi-agent-workflow
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../.claude/settings.json"

# Extract hooks section and replace source-app
HOOKS_JSON=$(jq --arg name "$PROJECT_NAME" '.hooks | walk(if type == "string" then gsub("cc-hook-multi-agent-obvs"; $name) else . end)' "$TEMPLATE")

# Merge hooks into existing settings
jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# Create state file if it doesn't exist (enabled by default)
STATE_FILE=".claude/.observability-state"
if [ ! -f "$STATE_FILE" ]; then
    echo "enabled" > "$STATE_FILE"
fi

echo "✅ Updated $SETTINGS_FILE with source-app: $PROJECT_NAME"
echo "To revert: mv $SETTINGS_FILE.backup $SETTINGS_FILE"
echo ""
echo "Manage observability:"
echo "  Status:  $SCRIPT_DIR/observability-status.sh"
echo "  Disable: $SCRIPT_DIR/disable-observability.sh"
echo "  Enable:  $SCRIPT_DIR/enable-observability.sh"
