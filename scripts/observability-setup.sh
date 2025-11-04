#!/bin/bash
# Enhanced setup script for observability system
# Usage: ./scripts/observability-setup.sh /path/to/target-project [PROJECT_NAME]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
ORANGE='\033[38;5;208m'
LIME='\033[38;5;154m'      # Bright yellow-green for commands
BRIGHT_YELLOW='\033[38;5;226m'  # Bright yellow for file paths
BOLD='\033[1m'
DIM='\033[2m'
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
OVERWRITE_FILES=()

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

# Check for existing hook files
if [ -d "$CLAUDE_DIR/hooks/observability" ]; then
    # Find all hook files (.py files and directories)
    while IFS= read -r -d '' hook_file; do
        # Get relative path from target directory
        rel_path="${hook_file#$TARGET_DIR/}"
        OVERWRITE_FILES+=("$rel_path")
    done < <(find "$CLAUDE_DIR/hooks/observability" -type f -print0 2>/dev/null)

    # Also check for utils directory
    if [ -d "$CLAUDE_DIR/hooks/observability/utils" ]; then
        OVERWRITE_FILES+=(".claude/hooks/observability/utils/")
    fi
fi

# Check for existing status_line files
if [ -d "$CLAUDE_DIR/status_lines" ]; then
    while IFS= read -r -d '' status_file; do
        rel_path="${status_file#$TARGET_DIR/}"
        OVERWRITE_FILES+=("$rel_path")
    done < <(find "$CLAUDE_DIR/status_lines" -type f -print0 2>/dev/null)
fi

# Check for existing wrapper scripts
WRAPPER_SCRIPTS=("observability-start.sh" "observability-stop.sh" "observability-enable.sh" "observability-disable.sh" "observability-status.sh")
for script in "${WRAPPER_SCRIPTS[@]}"; do
    if [ -f "$TARGET_DIR/scripts/$script" ]; then
        OVERWRITE_FILES+=("scripts/$script")
    fi
done

# Check for existing agents
AGENT_FILES=("summary-processor.md" "changelog-manager.md" "ghcli.md" "primer-generator.md" "html-converter.md")
for agent in "${AGENT_FILES[@]}"; do
    if [ -f "$CLAUDE_DIR/agents/$agent" ]; then
        OVERWRITE_FILES+=(".claude/agents/$agent")
    fi
done

# Check for existing commands
COMMAND_FILES=("o-start.md" "o-stop.md" "o-status.md" "o-enable.md" "o-disable.md" "process-summaries.md" "generate-context.md" "generate-arch.md" "prime-quick.md" "prime-full.md")
for cmd in "${COMMAND_FILES[@]}"; do
    if [ -f "$CLAUDE_DIR/commands/$cmd" ]; then
        OVERWRITE_FILES+=(".claude/commands/$cmd")
    fi
done

# Check for existing planning commands
PLANNING_COMMAND_FILES=("convert-planning.md" "generate-prp.md" "execute-prp.md")
for cmd in "${PLANNING_COMMAND_FILES[@]}"; do
    if [ -f "$CLAUDE_DIR/commands/$cmd" ]; then
        OVERWRITE_FILES+=(".claude/commands/$cmd")
    fi
done

# Check for existing planning system files
PLANNING_FILES=(
    ".ai/AGENTS.md"
    ".ai/context_engineering.md"
    ".ai/planning/README.md"
    ".ai/planning/templates/PLANNING_TEMPLATE.md"
    ".ai/planning/templates/TASKS_TEMPLATE.md"
    ".ai/planning/prd/PLANNING_MIGRATE.md"
    ".ai/planning/prp/README.md"
)
for file in "${PLANNING_FILES[@]}"; do
    if [ -f "$TARGET_DIR/$file" ]; then
        OVERWRITE_FILES+=("$file")
    fi
done

# Check for PRP templates directory
if [ -d "$TARGET_DIR/.ai/planning/prp/templates" ]; then
    while IFS= read -r -d '' prp_file; do
        rel_path="${prp_file#$TARGET_DIR/}"
        OVERWRITE_FILES+=("$rel_path")
    done < <(find "$TARGET_DIR/.ai/planning/prp/templates" -type f -print0 2>/dev/null)
fi

# Summarize agent/command/script/hook overwrites
if [ ${#OVERWRITE_FILES[@]} -gt 0 ]; then
    # Count by category
    AGENT_COUNT=0
    COMMAND_COUNT=0
    SCRIPT_COUNT=0
    HOOK_COUNT=0
    STATUS_LINE_FILE_COUNT=0
    for file in "${OVERWRITE_FILES[@]}"; do
        if [[ $file == .claude/agents/* ]]; then
            ((AGENT_COUNT++)) || true
        elif [[ $file == .claude/commands/* ]]; then
            ((COMMAND_COUNT++)) || true
        elif [[ $file == scripts/* ]]; then
            ((SCRIPT_COUNT++)) || true
        elif [[ $file == .claude/hooks/observability/* ]]; then
            ((HOOK_COUNT++)) || true
        elif [[ $file == .claude/status_lines/* ]]; then
            ((STATUS_LINE_FILE_COUNT++)) || true
        fi
    done

    if [ $HOOK_COUNT -gt 0 ]; then
        WARNINGS+=("$HOOK_COUNT hook file(s)")
    fi
    if [ $STATUS_LINE_FILE_COUNT -gt 0 ]; then
        WARNINGS+=("$STATUS_LINE_FILE_COUNT status line file(s)")
    fi
    if [ $AGENT_COUNT -gt 0 ]; then
        WARNINGS+=("$AGENT_COUNT agent file(s)")
    fi
    if [ $COMMAND_COUNT -gt 0 ]; then
        WARNINGS+=("$COMMAND_COUNT command file(s)")
    fi
    if [ $SCRIPT_COUNT -gt 0 ]; then
        WARNINGS+=("$SCRIPT_COUNT script file(s)")
    fi
fi

# ===== SHOW WARNINGS AND PROMPT =====

echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                      INSTALLATION PLAN                                    ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show overwrite warnings first if any
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${BOLD}${YELLOW}⚠️  OVERWRITES DETECTED${NC}"
    echo ""
    echo -e "${YELLOW}The following existing items will be ${BOLD}overwritten${NC}${YELLOW}:${NC}"
    echo ""

    # Show summary warnings
    for warning in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}▸${NC} $warning"
    done
    echo ""

    # Show detailed file list
    if [ ${#OVERWRITE_FILES[@]} -gt 0 ]; then
        echo -e "${DIM}Specific files (${#OVERWRITE_FILES[@]} total):${NC}"
        for file in "${OVERWRITE_FILES[@]}"; do
            echo -e "    ${DIM}→${NC} ${BRIGHT_YELLOW}$file${NC}"
        done
        echo ""
    fi

    # Backup notice
    if [ "$SETTINGS_EXISTS" = true ]; then
        BACKUP_FILE="$SETTINGS_FILE.$(date +%s)"
        echo -e "  ${GREEN}✓${NC} Backup will be created: ${DIM}$BACKUP_FILE${NC}"
        echo ""
    fi

    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

echo -e "${GREEN}The following components will be installed:${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}.ai/planning/${NC}"
echo -e "      ${DIM}Context Engineering system with PRP framework and Work Table${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}.claude/hooks/observability/${NC}"
echo -e "      ${DIM}PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, etc.${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}.claude/status_lines/${NC}"
echo -e "      ${DIM}Real-time agent status display${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}./scripts/${NC} ${DIM}(management script wrappers)${NC}"
echo -e "      ${DIM}observability-start.sh, -stop.sh, -status.sh, -enable.sh, -disable.sh${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}.claude/commands/${NC}"
echo -e "      ${DIM}Slash commands for observability management and context generation${NC}"
echo -e "  ${DIM}▸${NC} ${BRIGHT_YELLOW}.claude/agents/${NC}"
echo -e "      ${ORANGE}●${NC} ${BOLD}${ORANGE}Jerry${NC} - Generates AI summaries for hook events"
echo -e "      ${BLUE}●${NC} ${BOLD}${BLUE}Pedro${NC} - Maintains ${BRIGHT_YELLOW}CHANGELOG.md${NC} with proper formatting"
echo -e "      ${CYAN}●${NC} ${BOLD}${CYAN}Mark${NC} - Handles GitHub PRs, issues, comments via ${BRIGHT_YELLOW}.github/workflows/gh-dispatch-ai.yml${NC}"
echo -e "      ${GREEN}●${NC} ${BOLD}${GREEN}Atlas${NC} - Generates ${BRIGHT_YELLOW}context.md${NC} and ${BRIGHT_YELLOW}arch.md${NC} for AI priming"
echo -e "      ${PURPLE}●${NC} ${BOLD}${PURPLE}Bixby${NC} - Converts markdown/text to styled HTML"
echo ""

# Show settings.json status only if NO overwrites were shown above
if [ ${#WARNINGS[@]} -eq 0 ]; then
    if [ "$SETTINGS_EXISTS" = true ]; then
        echo -e "${GREEN}✓${NC} Existing settings.json will be preserved"
    else
        echo -e "${GREEN}✓${NC} New settings.json will be created"
    fi
    echo ""
fi

if [ "$INSTALL_ALL" = "1" ]; then
    echo "INSTALL_ALL=1 detected, skipping prompts..."
    REPLY="y"
else
    echo -e "${DIM}Press ${YELLOW}D${NC}${DIM} for detailed component information${NC}"
    echo -e -n "Continue with installation? (${GREEN}Y${NC}/${YELLOW}D${NC}/${RED}N${NC}): "
    read -n 1 -r REPLY
    echo

    # Show documentation if requested
    if [[ $REPLY =~ ^[Dd]$ ]]; then
        echo ""
        echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║                        COMPONENT DETAILS                                  ║${NC}"
        echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Agents${NC} ${BRIGHT_YELLOW}.claude/agents/${NC}"
        echo ""
        echo -e "  ${ORANGE}●${NC} ${BOLD}${ORANGE}Jerry${NC} - Generates AI summaries for hook events"
        echo -e "  ${BLUE}●${NC} ${BOLD}${BLUE}Pedro${NC} - Maintains ${BRIGHT_YELLOW}CHANGELOG.md${NC} with proper formatting"
        echo -e "  ${CYAN}●${NC} ${BOLD}${CYAN}Mark${NC} - Handles GitHub PRs, issues, comments via ${BRIGHT_YELLOW}.github/workflows/gh-dispatch-ai.yml${NC}"
        echo -e "  ${GREEN}●${NC} ${BOLD}${GREEN}Atlas${NC} - Generates ${BRIGHT_YELLOW}context.md${NC} and ${BRIGHT_YELLOW}arch.md${NC} for AI priming"
        echo -e "  ${PURPLE}●${NC} ${BOLD}${PURPLE}Bixby${NC} - Converts markdown/text to styled HTML"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Config Files${NC}"
        echo ""
        echo -e "  ${BRIGHT_YELLOW}.claude/.observability-config${NC}  - System paths and project name"
        echo -e "  ${BRIGHT_YELLOW}.claude/.observability-state${NC}   - Event streaming state"
        echo -e "  ${BRIGHT_YELLOW}.claude/settings.json${NC}          - Hooks and status line config"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Slash Commands${NC} ${BRIGHT_YELLOW}.claude/commands/${NC}"
        echo ""
        echo -e "  ${LIME}/o-start${NC}           - Start observability server + client dashboard"
        echo -e "  ${LIME}/o-stop${NC}            - Stop observability system"
        echo -e "  ${LIME}/o-status${NC}          - Check system status"
        echo -e "  ${LIME}/o-enable${NC}          - Enable event streaming"
        echo -e "  ${LIME}/o-disable${NC}         - Disable event streaming"
        echo -e "  ${LIME}/process-summaries${NC} - Generate AI summaries on-demand"
        echo -e "  ${LIME}/generate-context${NC}  - Create ${BRIGHT_YELLOW}context.md${NC} with git state + CHANGELOG"
        echo -e "  ${LIME}/generate-arch${NC}     - Create ${BRIGHT_YELLOW}arch.md${NC} with codebase architecture"
        echo -e "  ${LIME}/prime-quick${NC}       - Quick prime from existing context files"
        echo -e "  ${LIME}/prime-full${NC}        - Full context generation via Atlas"
        echo -e "  ${LIME}/convert-planning${NC}  - Convert unstructured plans to PLANNING.md format"
        echo -e "  ${LIME}/generate-prp${NC}     - Generate PRPs from PLANNING.md or proposals"
        echo -e "  ${LIME}/execute-prp${NC}      - Implement features from PRP instances"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Hooks${NC} ${BRIGHT_YELLOW}.claude/hooks/observability/${NC}"
        echo ""
        echo -e "  PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop,"
        echo -e "  SessionStart, SessionEnd, PreCompact"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Status Lines${NC} ${BRIGHT_YELLOW}.claude/status_lines/${NC}"
        echo ""
        echo -e "  Real-time agent states, event counts, and system health"
        echo ""

        echo -e "${BOLD}${GREEN}▸ Planning System${NC} ${BRIGHT_YELLOW}.ai/planning/${NC}"
        echo ""
        echo -e "  ${BRIGHT_YELLOW}.ai/AGENTS.md${NC}                           - Planning directives for agents"
        echo -e "  ${BRIGHT_YELLOW}.ai/planning/README.md${NC}                  - Complete workflow documentation"
        echo -e "  ${BRIGHT_YELLOW}.ai/planning/templates/${NC}                 - PLANNING + TASKS templates"
        echo -e "  ${BRIGHT_YELLOW}.ai/planning/prd/PLANNING.md${NC}           - Work Table (tracked)"
        echo -e "  ${BRIGHT_YELLOW}.ai/planning/prp/templates/${NC}            - PRP generation templates"
        echo ""

        echo -e -n "Continue with installation? (${GREEN}Y${NC}/${RED}N${NC}): "
        read -n 1 -r REPLY
        echo
    fi

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation aborted. No changes made."
        exit 0
    fi
fi

# ===== EXECUTE INSTALLATION =====

echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                  INSTALLING OBSERVABILITY SYSTEM                          ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/status_lines"
mkdir -p "$TARGET_DIR/scripts"
mkdir -p "$TARGET_DIR/.ai/planning/templates"
mkdir -p "$TARGET_DIR/.ai/planning/prd"
mkdir -p "$TARGET_DIR/.ai/planning/prp/templates"
mkdir -p "$TARGET_DIR/.ai/scratch"

# Copy files
echo "Copying observability hooks..."
cp -R "$SOURCE_DIR/.claude/hooks/observability" "$CLAUDE_DIR/hooks/"

echo "Copying status lines..."
cp -R "$SOURCE_DIR/.claude/status_lines/"* "$CLAUDE_DIR/status_lines/"

echo "Generating management script wrappers..."
generate_wrapper "observability-start.sh"
generate_wrapper "observability-stop.sh"
generate_wrapper "observability-enable.sh"
generate_wrapper "observability-disable.sh"
generate_wrapper "observability-status.sh"

echo "Copying agents..."
cp "$SOURCE_DIR/.claude/agents/summary-processor.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/changelog-manager.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/ghcli.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/primer-generator.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/agents/html-converter.md" "$CLAUDE_DIR/agents/" 2>/dev/null || true

# Copy observability slash commands
echo ""
echo -e "${GREEN}Copying observability commands...${NC}"
cp "$SOURCE_DIR/.claude/commands/o-start.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/o-stop.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/o-status.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/o-enable.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/o-disable.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/process-summaries.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/generate-context.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/generate-arch.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/prime-quick.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/prime-full.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true

# Copy planning system commands
echo ""
echo -e "${GREEN}Copying planning system commands...${NC}"
cp "$SOURCE_DIR/.claude/commands/convert-planning.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/generate-prp.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SOURCE_DIR/.claude/commands/execute-prp.md" "$CLAUDE_DIR/commands/" 2>/dev/null || true

# Copy planning system templates and docs
echo "Copying planning system templates..."
cp "$SOURCE_DIR/.ai/planning/README.md" "$TARGET_DIR/.ai/planning/" 2>/dev/null || true
cp "$SOURCE_DIR/.ai/planning/templates/PLANNING_TEMPLATE.md" "$TARGET_DIR/.ai/planning/templates/" 2>/dev/null || true
cp "$SOURCE_DIR/.ai/planning/templates/TASKS_TEMPLATE.md" "$TARGET_DIR/.ai/planning/templates/" 2>/dev/null || true
cp "$SOURCE_DIR/.ai/planning/prd/PLANNING_MIGRATE.md" "$TARGET_DIR/.ai/planning/prd/" 2>/dev/null || true
cp "$SOURCE_DIR/.ai/planning/prp/README.md" "$TARGET_DIR/.ai/planning/prp/" 2>/dev/null || true
cp -R "$SOURCE_DIR/.ai/planning/prp/templates/"* "$TARGET_DIR/.ai/planning/prp/templates/" 2>/dev/null || true

# Copy agent directives
echo "Copying agent directives..."
cp "$SOURCE_DIR/.ai/AGENTS.md" "$TARGET_DIR/.ai/" 2>/dev/null || true
cp "$SOURCE_DIR/.ai/context_engineering.md" "$TARGET_DIR/.ai/" 2>/dev/null || true

# Handle settings.json
echo "Configuring settings.json..."

if [ "$SETTINGS_EXISTS" = true ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "  Backup created: $BACKUP_FILE"

    # Extract observability settings from template
    TEMPLATE="$SOURCE_DIR/.claude/settings.json"
    HOOKS_JSON=$(jq '.hooks' "$TEMPLATE")
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
    # Copy entire settings.json template
    TEMPLATE="$SOURCE_DIR/.claude/settings.json"
    cp "$TEMPLATE" "$SETTINGS_FILE"
    echo "  New settings.json created from template"
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
  "PROJECT_NAME": "$PROJECT_NAME",
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
.env*

# AI Planning System (instance files)
.ai/planning/prp/instances/
.ai/planning/prp/proposals/
.ai/planning/prp/archive/
.ai/scratch/
GITIGNORE_EOF
        echo "Updated .gitignore with observability entries (duplicates are harmless if already present)"
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
.env*

# AI Planning System (instance files)
.ai/planning/prp/instances/
.ai/planning/prp/proposals/
.ai/planning/prp/archive/
.ai/scratch/
GITIGNORE_EOF
    echo "Created .gitignore with observability entries"
fi

# ===== SUCCESS MESSAGE =====

echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                    INSTALLATION COMPLETE ✅                               ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Project:${NC} ${GREEN}$PROJECT_NAME${NC}"
echo -e "${BOLD}Target:${NC} ${DIM}$TARGET_DIR${NC}"
echo ""
echo -e "${BOLD}${GREEN}Next steps:${NC}"
echo -e "  ${GREEN}1.${NC} Restart Claude Code to load new configuration"
echo -e "  ${GREEN}2.${NC} Start observability server: ${LIME}cd $SOURCE_DIR && ./scripts/observability-start.sh${NC}"
echo -e "  ${GREEN}3.${NC} Open dashboard: ${CYAN}http://localhost:5173${NC}"
echo -e "  ${GREEN}4.${NC} Run any Claude Code command to test"
echo ""
echo -e "${BOLD}${GREEN}Manage observability:${NC}"
echo -e "  Slash commands: ${LIME}/o-status${NC}, ${LIME}/o-start${NC}, ${LIME}/o-stop${NC}, ${LIME}/o-enable${NC}, ${LIME}/o-disable${NC}"
echo -e "  Scripts: ${BRIGHT_YELLOW}$TARGET_DIR/scripts/observability-status.sh${NC}"
echo ""
