# Branch Context: feat/infrastructure-updates

## Goal
Enhance infrastructure with config system, dynamic wrappers, unified setup, and changelog management

## Current State
- **Branch**: `feat/infrastructure-updates` (HEAD: 1e69a37 Add Pedro changelog manager with verification)
- **Main Branch**: `main`
- **Status**: 🟡 Open PR #3 - Infrastructure Updates (not yet merged)
- **Files Changed**: 50+ files (modifications, deletions, additions)

## Recent Changes (from CHANGELOG)

### Latest Work (Unreleased / PR #3)
- FIX: Remove hardcoded project names, read from `.observability-config` dynamically
- FIX: Add missing directory structure (`.gitkeep` files in `apps/server/data/` and `logs/`)
- DOCS: Bun binary accessibility with symlink creation for non-interactive shells
- CHORE: Move all template files to `templates/` directory with `.template` extension
- DOCS: Add comprehensive root cause analysis with solutions and testing
- FEAT: Add mandatory verification step to Pedro changelog manager
- REFACTOR: Update verification to check only added commits

### v1.0.1 (2025-10-25 - Already Merged)
- FEAT: Automated setup script with pre-flight checks and dynamic wrapper generation
- FEAT: Observability configuration system (`.observability-config` and state files)
- FEAT: Bash config loader utility for shell scripts
- REFACTOR: Move all hooks to `.claude/hooks/observability/` subdirectory
- REFACTOR: Update hardcoded paths to use config-based paths
- DOCS: Complete README overhaul with unified setup guide

## Progress
- [x] Config system implementation (.observability-config)
- [x] Dynamic wrapper script generation
- [x] Pedro changelog manager with verification
- [x] Template directory organization
- [x] Hook system reorganization and refactoring
- [x] Setup script with pre-flight checks
- [ ] PR #3 merge to main
- [ ] Release v1.0.2

## Project Structure
```
.claude/
├── agents/ (Specialized AI agents)
│   ├── summary-processor.md (Jerry - Haiku 4.5)
│   ├── changelog-manager.md (Pedro - CHANGELOG mgmt)
│   ├── html-converter.md (Bixby - MD to HTML)
│   └── primer-generator.md (Atlas - Context/arch)
├── commands/ (Custom slash commands)
│   ├── generate-context.md (Context primer)
│   ├── generate-arch.md (Architecture primer)
│   ├── prime-quick.md (Read existing primers)
│   ├── prime-full.md (Generate fresh primers)
│   ├── process-summaries.md (Jerry dispatch)
│   ├── o-start/stop/status/enable/disable.md (System control)
│   └── quick-plan.md (Implementation planning)
├── hooks/observability/
│   ├── send_event.py (Core event sender)
│   ├── session_start.py (Session initialization)
│   ├── pre_tool_use.py (Tool validation)
│   ├── post_tool_use.py (Result logging)
│   ├── notification.py (User interactions)
│   ├── stop.py (Session completion)
│   ├── subagent_stop.py (Subagent completion)
│   └── utils/ (Shared utilities: LLM, TTS, HITL)
├── settings.json (Hook configuration template)
├── .observability-state (Runtime state: enabled/disabled)
└── .observability-config (Environment config - gitignored)

apps/
├── server/ (Bun TypeScript server)
│   ├── src/
│   │   ├── index.ts (HTTP/WebSocket endpoints)
│   │   ├── db.ts (SQLite management)
│   │   ├── theme.ts (Theme management)
│   │   └── types.ts (TypeScript interfaces)
│   ├── data/ (SQLite database - gitignored)
│   └── logs/ (Server logs - gitignored)
└── client/ (Vue 3 TypeScript client)
    ├── src/
    │   ├── App.vue (Main app + WebSocket)
    │   ├── components/ (EventTimeline, FilterPanel, etc.)
    │   ├── composables/ (WebSocket, colors, chart data)
    │   └── types.ts (TypeScript interfaces)
    └── logs/ (Client logs - gitignored)

scripts/
├── observability-start.sh (Launch server + client)
├── observability-stop.sh (Stop processes)
├── observability-setup.sh (Install to other projects)
├── observability-enable.sh (Enable event streaming)
├── observability-disable.sh (Disable event streaming)
└── git-ai.sh (Git with AI attribution)

templates/
└── *.template (Configuration templates)
```

## Key Configuration Files

### `.observability-config` (Generated on setup)
```json
{
  "MULTI_AGENT_WORKFLOW_PATH": "/absolute/path",
  "SERVER_URL": "http://localhost:4000",
  "CLIENT_URL": "http://localhost:5173",
  "PROJECT_NAME": "auto-detected"
}
```

### `.observability-state`
Contains single line: `enabled` or `disabled`

## Agents Overview

### Jerry (Summary Processor)
- Model: Haiku 4.5
- Role: On-demand AI summaries for hook events
- Auto-dispatch: User says "Process summaries from .summary-prompt.txt"
- Summary format: One sentence, <15 words, present tense

### Pedro (Changelog Manager)
- Role: CHANGELOG maintenance with verification
- Latest feature: Mandatory verification step before commits
- Checks: Only newly added commits

### Atlas (Primer Generator)
- Model: Haiku (fast)
- Role: Generates context and architecture primers
- Output: `.ai/scratch/context-primer.md` and `arch-primer.md` (gitignored)

### Bixby (HTML Converter)
- Model: Haiku
- Role: Converts markdown to styled HTML (formatter, not content creator)

### Mark (GitHub Operations)
- Role: ALL GitHub CLI operations with provenance
- Restriction: No direct `gh` calls from other agents

## Event System Architecture

### Hook Event Types
- PreToolUse: Tool validation before execution
- PostToolUse: Tool result logging
- Notification: User interactions
- Stop: Session completion with optional transcript
- SubagentStop: Subagent task completion
- UserPromptSubmit: User prompt logging
- SessionStart: Session initialization with context loading
- SessionEnd: Session cleanup

### Data Flow
Claude Code → Hook Script → send_event.py → Server (HTTP POST) → SQLite → WebSocket → Vue Client

### Server Endpoints
- POST /events - Receive events
- GET /events/recent - Paginated event retrieval
- GET /events/filter-options - Filter values
- WS /stream - Real-time broadcasting
- POST /events/batch-summaries - Update summaries
- POST /projects/register - Project path registration
- POST /hitl/response - Human-in-the-loop responses

## Development Workflow

### Testing Changes
1. Run `/prime-quick` to load existing context (fast)
2. Run `/prime-full` to regenerate (if major changes)
3. Use `./scripts/observability-start.sh` to run full system
4. Test at http://localhost:5173

### Making Commits
- Use `./scripts/git-ai.sh commit -m "message"` for git operations
- Commit messages: <60 chars, imperative mood
- For GitHub operations: Dispatch Mark agent, never use `gh` directly

### Configuration Changes
- Update `.observability-config` in integrated projects if paths change
- Dynamic wrapper generation via `observability-setup.sh`
- All paths read from `.observability-config` at runtime

## Next Steps
- [ ] Merge PR #3 to main
- [ ] Release v1.0.2
- [ ] Document integration flow for external projects
- [ ] Add more comprehensive hook examples

## Notes
- Shared server instance: All integrated projects depend on this repo's server
- Critical: If repo moved/deleted, update `.observability-config` in integrated projects
- Config-driven: All hardcoded paths replaced with dynamic config loading
