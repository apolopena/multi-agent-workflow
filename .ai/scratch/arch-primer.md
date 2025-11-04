# Architecture

## Stack
Bun (TypeScript server) + Vue 3 (client) + Python (hooks) + SQLite + WebSocket

## Structure

### Core Directories
- `apps/server/` - Bun TypeScript server (port 4000), SQLite database
- `apps/client/` - Vue 3 TypeScript dashboard (port 5173), real-time WebSocket
- `.claude/hooks/observability/` - Python event capture scripts
- `.claude/agents/` - Specialized subagents (Jerry, Mark, Pedro, Atlas, Bixby)
- `.claude/commands/` - Slash commands (o-start, process-summaries, prime-*, generate-prp, execute-prp)
- `scripts/` - Management scripts (observability-*.sh, git-ai.sh, cleanup-old-planning-dirs.sh)
- `.ai/docs/` - Fetched API documentation
- `.ai/planning/` - Planning system (prd/, prp/, templates/)
- `.ai/scratch/` - Generated primers, TASKS.md (gitignored)
- `templates/` - Config templates

### Key Files
- `.claude/settings.json` - Hook configuration and permissions
- `.claude/.observability-config` - Environment-specific paths (gitignored)
- `.claude/.observability-state` - enabled/disabled state
- `.env` - API keys (two locations: root + apps/server/)
- `.ai/AGENTS.md` - Planning directives for agents
- `.ai/planning/README.md` - Complete Context Engineering workflow
- `CHANGELOG.md` - Version history with PR links
- `README.md` - Complete documentation
- `CLAUDE.md` - Project instructions for Claude Code

## Core Patterns

### Event System
- **Flow**: Claude Code → Hook Script → send_event.py → POST /events → SQLite → WebSocket → Vue Client
- **Event Envelope**: { source_app, session_id, hook_event_type, timestamp, payload, summary?, chat? }
- **Unique ID**: source_app:session_id (first 8 chars displayed)
- **Hook Types**: PreToolUse, PostToolUse, Notification, Stop, SubagentStop, UserPromptSubmit, SessionStart, SessionEnd, PreCompact

### Planning System (Context Engineering)
- **Mode 1 (Bulk)**: /generate-prp on PLANNING.md → Comprehensive PRPs for initial build → Rows become FROZEN
- **Mode 2 (Standalone)**: /generate-prp on proposal → Auto-adds Work Table row → Generates lean PRP
- **Mode 3 (Execution)**: /execute-prp on PRP instance → Implement feature → Update TASKS.md
- **Work Table**: WP-1 to WP-N (frozen), WP-10+ (growing), multi-engineer ID blocks (10-19, 20-29, 30-39)
- **Directory Structure**: .ai/planning/prd/, prp/templates/, prp/instances/, prp/proposals/, prp/archive/

### Hook Configuration Pattern
- **Two-step hooks**: Event-specific script + send_event.py
- **Flags**: --summarize (real-time summaries), --add-chat (include transcript), --notify (TTS)
- **Execution**: uv run via $CLAUDE_PROJECT_DIR for dynamic paths
- **Non-blocking**: Hooks continue silently if server unavailable

### Database Design
- **SQLite with WAL mode** (concurrent access)
- **Tables**: events, projects, themes, user_preferences
- **Indexes**: timestamp, session_id, hook_event_type, source_app
- **Auto-migration**: Schema changes applied on startup

### Agent Dispatch
- **Jerry** (Haiku 4.5): On-demand summaries, /process-summaries
- **Mark** (main model): ALL GitHub operations with provenance
- **Pedro** (main model): CHANGELOG maintenance with verification
- **Atlas** (Haiku): Context/arch primers (/prime-*, /generate-*)
- **Bixby** (Haiku): Markdown to HTML formatter

### Security Practices
- **Pre-Tool-Use Hook**: Blocks dangerous commands, prevents .env access
- **Permissions**: allow/ask/deny lists in settings.json
- **File Protection**: .env, .observability-config, logs/ gitignored
- **SSH Handling**: Always use git-ai.sh (keychain integration)

### WebSocket Architecture
- **Server**: Bun built-in WebSocket on /stream endpoint
- **Client**: Auto-reconnect with exponential backoff
- **Broadcast**: All events to all clients
- **HITL**: Bidirectional for agent interaction (60s timeout)

### Summary System
- **Real-time**: Anthropic API via hooks (costs ~cents per 10 summaries)
- **On-demand**: Jerry batch-processes from .summary-prompt.txt (free)
- **Format**: One sentence, <15 words, present tense, technical
- **Meta-events**: Jerry operations tagged, orange background

## Core Conventions

### Commit Messages
- Format: <60 chars, imperative mood
- Example: "Add feature X" not "Added feature X"

### Git Operations
- SSH commands: ALWAYS use ./scripts/git-ai.sh
- Benefits: Keychain integration, AI attribution, provenance

### GitHub Operations
- ALL write operations through Mark agent
- Read-only exception: Pedro can use gh release view
- Provenance: Claude_AI with session_id and timestamp

### File Paths
- Use absolute paths (not relative)
- Hooks use dynamic config via $CLAUDE_PROJECT_DIR

### Agent Rules
- Jerry: Summary processor only
- Mark: GitHub operations only
- Pedro: CHANGELOG only (with verification)
- Atlas: Primer generation only
- Bixby: Formatter only (NOT content creator)

### Planning Rules (from .ai/AGENTS.md)
- Never read .ai/planning/prp/instances/ unless user references specific file
- Batch file edits using one multi-edit call
- Use only dependencies in repo config or PRP context
- Never delete/overwrite code without explicit direction
- Ask questions when ambiguous
- Run validation commands before declaring complete
- Update TASKS.md when work finishes

## Adding Features

**New Hook Event:** Create hook script → Add to settings.json → Update constants.py emoji → Add Vue component if needed

**New Agent:** Create .md in .claude/agents/ → Define name, model, color, tools → Add auto-dispatch via command

**New Command:** Create .md in .claude/commands/ → Define prompt and workflow → Reference in settings.json if needed

**New Endpoint:** Add route in apps/server/src/index.ts → Database query → Update types.ts → Test with curl

**New Filter:** Add logic in server index.ts → Update /events/filter-options → Add to FilterPanel.vue

**New PRP Feature:** Create proposal in .ai/planning/prp/proposals/WP-XX_name.md → /generate-prp → /execute-prp

**New Integration:** Run observability-setup.sh → Creates .claude/ → Generates wrappers → Updates .gitignore

## Key Workflows

### Normal Event Capture
Claude Action → Hook Script → send_event.py → POST /events → SQLite → WebSocket → Vue Client

### HITL Response
Hook asks permission → Event with hitl_question → Dashboard dialog → POST /hitl/response → Agent continues

### Summary Generation (On-Demand)
Click "Generate Summaries" → .summary-prompt.txt created → /process-summaries → Jerry reads → Generates → Database updated

### GitHub Operations
Request PR → Mark dispatched → Gathers context → gh workflow dispatch → PR created with provenance

### Primer Generation
/prime-full → Atlas reads CHANGELOG → Runs git commands → /generate-context + /generate-arch → Writes to .ai/scratch/

### Planning Workflow (Bulk)
Create PLANNING.md with WP-1 to WP-N → /generate-prp → Comprehensive PRPs generated → Rows FROZEN

### Planning Workflow (Standalone)
Create proposal WP-XX_name.md → /generate-prp → Auto-adds Work Table row → Lean PRP generated → /execute-prp

### Setup New Project
Run observability-setup.sh → Show warnings → Copy hooks → Generate wrappers → Update config → Restart Claude Code

## Performance

### Event Handling
- Typical: 10-50 events/minute (active coding)
- Peak: 100+ events/minute (rapid tool execution)
- Storage: ~500 bytes per event (JSON)
- Client limit: 100 events displayed (configurable)

### Database
- WAL mode: Concurrent reads + writes
- Index on timestamp: Fast time-range queries
- Auto-cleanup: Configurable retention

### Error Handling
- Server unavailable: Hooks continue silently
- Database corruption: WAL recovers gracefully
- WebSocket disconnect: Client auto-reconnects, fetches missed events
- HITL timeout: 60s → auto-deny → agent handles gracefully

## Tech Details

### Server (Bun)
- Runtime: Bun (not Node.js)
- Database: bun:sqlite (not better-sqlite3)
- WebSocket: Built-in (not ws package)
- Port: 4000, .env from project root

### Client (Vue 3)
- Framework: Vue 3 Composition API
- Build: Vite, Styling: Tailwind CSS
- Port: 5173, Chart: Canvas API

### Hooks (Python)
- Language: Python 3.8+
- Package Manager: Astral uv (embedded)
- LLMs: Anthropic Claude, OpenAI
- TTS: ElevenLabs, OpenAI (with mpv fallback), pyttsx3
- Media Player: mpv

### Deployment
- Single instance: Recommended (shared database, centralized monitoring)
- Production: Database backup (WAL automatic), event retention policies, rate limiting
