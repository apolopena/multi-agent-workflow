# Architecture

## Stack
Bun (TypeScript server) + Vue 3 (client) + Python (hooks) + SQLite + WebSocket

## Structure

### Core Directories
- `apps/server/` - Bun TypeScript server (port 4000), SQLite database
- `apps/client/` - Vue 3 TypeScript dashboard (port 5173), real-time WebSocket
- `.claude/hooks/observability/` - Python event capture scripts
- `.claude/agents/` - Specialized subagents (Jerry, Mark, Pedro, Atlas, Bixby)
- `.claude/commands/` - Slash commands (o-start, process-summaries, prime-*, etc.)
- `scripts/` - Management scripts (observability-*.sh, git-ai.sh)
- `.ai/docs/` - Fetched API documentation
- `.ai/prd/` - Product requirements
- `.ai/prp/` - Project roadmap/planning
- `.ai/scratch/` - Generated primers (gitignored)
- `templates/` - Config templates

### Key Files
- `.claude/settings.json` - Hook configuration and permissions
- `.claude/.observability-config` - Environment-specific paths (gitignored)
- `.claude/.observability-state` - enabled/disabled state
- `.env` - API keys (two locations: root + apps/server/)
- `CHANGELOG.md` - Version history with PR links
- `README.md` - Complete documentation
- `CLAUDE.md` - Project instructions for Claude Code

## Core Patterns

### Event System
- **Flow**: Claude Code → Hook Script → send_event.py → POST /events → SQLite → WebSocket → Vue Client
- **Event Envelope**: { source_app, session_id, hook_event_type, timestamp, payload, summary?, chat? }
- **Unique ID**: source_app:session_id (first 8 chars displayed)
- **Hook Types**: PreToolUse, PostToolUse, Notification, Stop, SubagentStop, UserPromptSubmit, SessionStart, SessionEnd, PreCompact

### Hook Configuration Pattern
- **Two-step hooks**: Each hook type runs event-specific script + send_event.py
- **Flags**: --summarize (real-time summaries), --add-chat (include transcript), --notify (TTS)
- **Execution**: uv run via $CLAUDE_PROJECT_DIR for dynamic paths
- **Non-blocking**: Hooks continue silently if server unavailable

### Configuration System
- **Runtime Config**: .observability-config loaded dynamically (no hardcoded paths)
- **State Management**: .observability-state (enabled/disabled, no restart needed)
- **Wrapper Pattern**: Projects reference central repo via config, enabling repo moves
- **Setup Warnings**: v1.0.5 shows comprehensive overwrite warnings before modifying files

### Database Design
- **SQLite with WAL mode** (concurrent access)
- **Tables**: events, projects, themes, user_preferences
- **Indexes**: timestamp, session_id, hook_event_type, source_app
- **Auto-migration**: Schema changes applied on startup via column checks

### Agent Dispatch
- **Jerry** (Haiku 4.5): On-demand summaries, auto-dispatch from /process-summaries
- **Mark** (main model): ALL GitHub operations with provenance tracking
- **Pedro** (main model): CHANGELOG maintenance with verification
- **Atlas** (Haiku): Generate context/arch primers (/prime-*, /generate-*)
- **Bixby** (Haiku): Markdown to HTML formatter (not content creator)

### WebSocket Architecture
- **Server**: Bun built-in WebSocket on /stream endpoint
- **Client**: Auto-reconnect with exponential backoff
- **Broadcast**: All events sent to all connected clients
- **HITL**: Bidirectional WebSocket for agent interaction

### HITL (Human-in-the-Loop)
- **Flow**: Hook asks permission → Event with hitl_question → Dashboard dialog → POST /hitl/response → Agent receives approval/denial
- **Timeout**: 60 seconds (auto-deny)
- **Routing**: Session-aware (response sent to specific agent)
- **Implementation**: utils/hitl.py with ask_permission function

### Security Practices
- **Pre-Tool-Use Hook**: Blocks dangerous commands (rm -rf), prevents .env access
- **Permissions**: allow/ask/deny lists in settings.json
- **File Protection**: .env, .observability-config, logs/ all gitignored
- **Validation**: Event schema validation, timestamp checks, session ID verification
- **SSH Handling**: Always use git-ai.sh for SSH operations (keychain integration)

### Color System
- **App Colors**: Assigned per source_app (consistent across sessions)
- **Session Colors**: Assigned per session_id (visual distinction)
- **Dual Border**: Left = app color, second = session color
- **Chart Bars**: Session-colored with event type emojis

### Summary System
- **Real-time**: Anthropic API via hooks (costs ~cents per 10 summaries)
- **On-demand**: Jerry subagent batch-processes from .summary-prompt.txt (free)
- **Format**: One sentence, <15 words, present tense, technical
- **Meta-events**: Jerry operations tagged with [Meta-event: prefix, orange background

## Core Conventions

### Commit Messages
- Format: <60 chars, imperative mood
- Example: "Add feature X" not "Added feature X"

### Git Operations
- SSH commands: ALWAYS use ./scripts/git-ai.sh (commit, push, pull, fetch, clone)
- Benefits: Keychain integration, AI attribution, provenance metadata

### GitHub Operations
- ALL write operations through Mark agent (PRs, issues, comments)
- Read-only exception: Pedro can use gh release view
- Provenance: Claude_AI with session_id and timestamp
- Workflow: Mark dispatches .github/workflows/gh-dispatch-ai.yml

### File Paths
- Use absolute paths (not relative)
- Hooks use dynamic config loading via $CLAUDE_PROJECT_DIR
- Commands read from .observability-config

### Agent Rules
- Jerry: Summary processor only (NOT for general tasks)
- Mark: GitHub operations only (NO EXCEPTIONS)
- Pedro: CHANGELOG only (with mandatory verification)
- Atlas: Primer generation only (context/arch)
- Bixby: Formatter only (NOT content creator)

## Adding Features

**New Hook Event:** Create hook script → Add to settings.json → Update constants.py emoji mapping → Add Vue component if needed

**New Agent:** Create .md in .claude/agents/ → Define name, description, model, color, tools → Add auto-dispatch via command

**New Command:** Create .md in .claude/commands/ → Define prompt and workflow → Reference in .claude/settings.json if custom trigger needed

**New Endpoint:** Add route in apps/server/src/index.ts → Add database query if needed → Update types.ts → Test with curl

**New Filter:** Add filter logic in apps/server/src/index.ts → Update /events/filter-options → Add to Vue FilterPanel.vue

**New Chart:** Create composable in apps/client/src/composables/ → Add component → Integrate into App.vue → Test real-time updates

**New Integration:** Run observability-setup.sh in target project → Creates .claude/ structure → Generates wrappers → Updates .gitignore

## Project Integration

### Setup Process
1. Run `observability-setup.sh . [PROJECT_NAME]` from target project
2. Script shows comprehensive overwrite warnings (v1.0.5)
3. Creates .claude/ directory with hooks, agents, commands
4. Generates .observability-config with path to central repo
5. Creates wrapper scripts in project's ./scripts/
6. Updates .gitignore with observability entries
7. Merges with existing settings.json if present

### Shared Architecture
- All projects send events to central server (http://localhost:4000)
- Single SQLite database for all integrated projects
- Dashboard shows events from all projects simultaneously
- Projects depend on central repo location (critical)

### Recovery
- Repo moved: Update .observability-config in each project
- Repo deleted: Re-clone and re-run setup scripts
- To disconnect: Remove hooks from settings.json

## Performance

### Event Handling
- Typical: 10-50 events/minute (active coding)
- Peak: 100+ events/minute (rapid tool execution)
- Storage: ~500 bytes per event (JSON)
- Client limit: 100 events displayed (configurable via VITE_MAX_EVENTS_TO_DISPLAY)

### Database
- WAL mode: Concurrent reads + writes
- Index on timestamp: Fast time-range queries
- Auto-cleanup: Configurable retention policies

### WebSocket
- Broadcast latency: <100ms to all clients
- Auto-reconnect: Every 3 seconds with backoff
- Event fetch on reconnect: No data loss

### Error Handling
- Server unavailable: Hooks continue silently (non-blocking)
- Database corruption: WAL recovers gracefully
- WebSocket disconnect: Client auto-reconnects, fetches missed events
- HITL timeout: 60 seconds → auto-deny → agent handles gracefully

## Tech Details

### Server (Bun)
- Runtime: Bun (not Node.js)
- Database: bun:sqlite (not better-sqlite3)
- WebSocket: Built-in (not ws package)
- Port: 4000
- .env loading: Automatic from project root
- Dependencies: sqlite, sqlite3

### Client (Vue 3)
- Framework: Vue 3 Composition API
- Build: Vite (not webpack)
- Styling: Tailwind CSS
- Port: 5173
- Chart: Canvas API (custom renderer)

### Hooks (Python)
- Language: Python 3.8+
- Package Manager: Astral uv (embedded)
- LLMs: Anthropic Claude, OpenAI
- TTS: ElevenLabs, OpenAI, pyttsx3
- Media Player: mpv

### Deployment
- Single instance: Recommended (shared database, centralized monitoring)
- Multi-instance: Advanced (separate databases, no cross-project visibility)
- Production: Database backup (WAL automatic), event retention policies, rate limiting

## Key Workflows

### Normal Event Capture
Claude Action → Hook Script → send_event.py → POST /events → SQLite → WebSocket → Vue Client

### HITL Response
Hook asks permission → Event with hitl_question → Dashboard dialog → POST /hitl/response → Server routes to agent → Agent continues

### Summary Generation (On-Demand)
Click "Generate Summaries" → .summary-prompt.txt created → /process-summaries → Jerry reads → Generates summaries → POST batch → Database updated → Client refreshed

### GitHub Operations
Request PR → Mark dispatched → Gathers context → gh workflow dispatch → PR created with provenance → Results reported

### Primer Generation
/prime-full → Atlas reads CHANGELOG → Runs git commands → /generate-context + /generate-arch → Writes primers to .ai/scratch/

### Setup New Project
Run observability-setup.sh → Show warnings → Copy hooks → Generate wrappers → Update config → Update .gitignore → Restart Claude Code
