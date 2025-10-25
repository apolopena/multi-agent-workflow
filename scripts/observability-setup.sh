#!/bin/bash
# Enhanced setup script for observability system
# Usage: ./scripts/observability-setup.sh /path/to/target-project [PROJECT_NAME]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get target directory
TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory required${NC}"
    echo "Usage: $0 /path/to/target-project [PROJECT_NAME]"
    exit 1
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Get script directory (source)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install with: sudo apt install jq"
    exit 1
fi

# Get project name
PROJECT_NAME="$2"
if [ -z "$PROJECT_NAME" ]; then
    # Try to get git repo name
    cd "$TARGET_DIR"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        PROJECT_NAME=$(basename -s .git $(git config --get remote.origin.url) 2>/dev/null)
        if [ -z "$PROJECT_NAME" ]; then
            # Fallback to directory name
            PROJECT_NAME=$(basename "$TARGET_DIR")
        fi
        echo "Auto-detected project name: $PROJECT_NAME"
    else
        # Not a git repo, use directory name
        PROJECT_NAME=$(basename "$TARGET_DIR")
        echo "Using directory name as project name: $PROJECT_NAME"
    fi
fi

# ===== WRAPPER GENERATION FUNCTION =====

generate_wrapper() {
    local script_name="$1"
    local wrapper_path="$TARGET_DIR/scripts/$script_name"

    cat > "$wrapper_path" << 'WRAPPER_EOF'
#!/bin/bash
# Auto-generated wrapper by observability-setup.sh
# Calls SCRIPT_NAME from multi-agent-workflow

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
TARGET_SCRIPT="$MULTI_AGENT_WORKFLOW_PATH/scripts/SCRIPT_NAME"
if [ ! -f "$TARGET_SCRIPT" ]; then
    echo "Error: Script not found: $TARGET_SCRIPT" >&2
    echo "The multi-agent-workflow installation may be incomplete." >&2
    exit 1
fi

# Execute the real script
exec "$TARGET_SCRIPT" "$@"
WRAPPER_EOF

    # Replace SCRIPT_NAME placeholder with actual script name
    sed -i "s/SCRIPT_NAME/$script_name/g" "$wrapper_path"
    chmod +x "$wrapper_path"
}

# ===== PRE-FLIGHT CHECKS (no writes yet) =====

echo ""
echo "=== Pre-flight Checks ==="

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory does not exist: $TARGET_DIR${NC}"
    exit 1
fi
echo "✓ Target directory exists"

# Check if .claude directory exists or will be created
CLAUDE_DIR="$TARGET_DIR/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    echo "✓ .claude directory exists"
else
    echo "✓ .claude directory will be created"
fi

# Check settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SETTINGS_EXISTS=false
WARNINGS=()

if [ -f "$SETTINGS_FILE" ]; then
    SETTINGS_EXISTS=true
    echo "✓ settings.json exists (will check for conflicts)"

    # Check for hooks
    if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
        WARNINGS+=("hooks")
    fi

    # Check for statusLine
    if jq -e '.statusLine' "$SETTINGS_FILE" > /dev/null 2>&1; then
        WARNINGS+=("statusLine")
    fi

    # Check for includeCoAuthoredBy
    if jq -e '.includeCoAuthoredBy' "$SETTINGS_FILE" > /dev/null 2>&1; then
        WARNINGS+=("includeCoAuthoredBy")
    fi
else
    echo "✓ settings.json will be created from template"
fi

# ===== SHOW WARNINGS AND PROMPT =====

echo ""
echo "=== Installation Plan ==="
echo ""

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNING: The following settings will be overwritten:${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo "  - $warning"
    done
    echo ""
fi

echo "The following will be installed:"
echo "  - .claude/hooks/observability/"
echo "  - .claude/status_lines/"
echo "  - ./scripts/ (management script wrappers)"
echo "  - .claude/agents/ (Jerry, observability-manager, Mark)"
echo "  - .claude/commands/ (process-summaries, etc.)"
echo ""

if [ "$SETTINGS_EXISTS" = true ]; then
    BACKUP_FILE="$SETTINGS_FILE.$(date +%s)"
    echo "Backup will be created: $BACKUP_FILE"
else
    echo "New settings.json will be created"
fi

echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation aborted. No changes made."
    exit 0
fi

# ===== EXECUTE INSTALLATION =====

echo ""
echo "=== Installing Observability System ==="

# Create directories
echo "Creating directories..."
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/status_lines"
mkdir -p "$TARGET_DIR/scripts"

# Copy files
echo "Copying observability hooks..."
cp -R "$SOURCE_DIR/.claude/hooks/observability" "$CLAUDE_DIR/hooks/"

echo "Copying status lines..."
cp -R "$SOURCE_DIR/.claude/status_lines/"* "$CLAUDE_DIR/status_lines/"

echo "Generating management script wrappers..."
generate_wrapper "start-system.sh"
generate_wrapper "stop-system.sh"
generate_wrapper "observability-enable.sh"
generate_wrapper "observability-disable.sh"
generate_wrapper "observability-status.sh"

echo "Copying agents..."
cp "$SOURCE_DIR/.claude/agents/summary-processor.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/observability-manager.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/mark.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true

echo "Copying commands..."
cp "$SOURCE_DIR/.claude/commands/process-summaries.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/bun-start.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/bun-stop.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true

# Handle settings.json
echo "Configuring settings.json..."

if [ "$SETTINGS_EXISTS" = true ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "  Backup created: $BACKUP_FILE"

    # Extract observability settings from template
    TEMPLATE="$SOURCE_DIR/.claude/settings.json"
    HOOKS_JSON=$(jq --arg name "$PROJECT_NAME" '.hooks | walk(if type == "string" then gsub("cc-hook-multi-agent-obvs"; $name) else . end)' "$TEMPLATE")
    STATUS_LINE_JSON=$(jq '.statusLine' "$TEMPLATE")
    CO_AUTHORED=$(jq '.includeCoAuthoredBy' "$TEMPLATE")

    # Merge into existing settings
    jq --argjson hooks "$HOOKS_JSON" \
       --argjson statusLine "$STATUS_LINE_JSON" \
       --argjson coAuthored "$CO_AUTHORED" \
       '.hooks = $hooks | .statusLine = $statusLine | .includeCoAuthoredBy = $coAuthored' \
       "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "  Settings merged successfully"
else
    # Create new settings.json from template
    TEMPLATE="$SOURCE_DIR/.claude/settings.json"
    jq --arg name "$PROJECT_NAME" \
       '{
         statusLine: .statusLine,
         includeCoAuthoredBy: .includeCoAuthoredBy,
         hooks: (.hooks | walk(if type == "string" then gsub("cc-hook-multi-agent-obvs"; $name) else . end))
       }' "$TEMPLATE" > "$SETTINGS_FILE"
    echo "  New settings.json created"
fi

# Create observability state file
STATE_FILE="$CLAUDE_DIR/.observability-state"
if [ ! -f "$STATE_FILE" ]; then
    echo "enabled" > "$STATE_FILE"
    echo "Created observability state file (enabled)"
fi

# Create observability config file
CONFIG_FILE="$CLAUDE_DIR/.observability-config"
cat > "$CONFIG_FILE" << EOF
{
  "MULTI_AGENT_WORKFLOW_PATH": "$SOURCE_DIR",
  "SERVER_URL": "http://localhost:4000",
  "CLIENT_URL": "http://localhost:5173"
}
EOF
echo "Created observability config file"

# Update .gitignore
GITIGNORE_FILE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    # Check if observability entries already exist
    if ! grep -q ".observability-config" "$GITIGNORE_FILE" 2>/dev/null; then
        cat >> "$GITIGNORE_FILE" << 'GITIGNORE_EOF'

# Python (observability hooks)
__pycache__/
*.py[cod]
*$py.class

# Observability (environment-specific)
.claude/.observability-state
.claude/.observability-config
.summary-prompt.txt
GITIGNORE_EOF
        echo "Updated .gitignore with observability entries"
    else
        echo ".gitignore already contains observability entries"
    fi
else
    # Create new .gitignore
    cat > "$GITIGNORE_FILE" << 'GITIGNORE_EOF'
# Python (observability hooks)
__pycache__/
*.py[cod]
*$py.class

# Observability (environment-specific)
.claude/.observability-state
.claude/.observability-config
.summary-prompt.txt
GITIGNORE_EOF
    echo "Created .gitignore with observability entries"
fi

# ===== SUCCESS MESSAGE =====

echo ""
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo ""
echo "Project name: $PROJECT_NAME"
echo "Target directory: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to load new configuration"
echo "  2. Start observability server: cd $SOURCE_DIR && ./scripts/start-system.sh"
echo "  3. Open dashboard: http://localhost:5173"
echo "  4. Run any Claude Code command to test"
echo ""
echo "Manage observability:"
echo "  Kim agent: 'Kim, check status' or 'Kim, disable observability'"
echo "  Scripts: $SOURCE_DIR/scripts/observability-status.sh"
echo ""
