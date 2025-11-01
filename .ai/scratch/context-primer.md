# Branch Context: main

## Goal
Stable production branch for multi-agent workflow system with observability and AI-powered development tools

## Recent Changes (from CHANGELOG)

### v1.0.5 (2025-10-30) - Latest
**PR #8: Enhance setup script with comprehensive overwrite warnings**
- FEAT: Enhanced setup script with comprehensive overwrite warnings listing all affected files and categorized summary

### v1.0.4 (2025-10-30)
**PR #7: Fix summary UX, .env loading, Atlas and Bixby agents**
- FEAT: Simplified summary generation with one-button operation hardcoded to repo root
- FIX: Fixed .env loading by running server from project root instead of apps/server
- FEAT: Add Atlas agent for generating context.md and architecture.md documentation
- FEAT: Add Bixby agent for HTML formatting operations
- FEAT: Implement project registration with database persistence
- REFACTOR: Reorganize documentation by moving ai_docs to .ai/docs
- CHORE: Remove demo-cc-agent directory and obsolete test/benchmark files
- FIX: Fix CHANGELOG version ordering to use proper semantic version sort
- FEAT: Update generate-context command with improved functionality
- CHORE: Clean up .claude configuration by removing deprecated agents and commands

### v1.0.3 (2025-10-29)
**PR #6: Add Pedro changelog manager with verification**
- FEAT: Add Pedro changelog manager with automated verification to prevent duplicate entries

### v1.0.2 (2025-10-28)
**PR #3: Infrastructure Updates**
- FIX: Fix critical infrastructure issues and refactor project config
- DOCS: Add anti-pattern examples to Pedro instructions
- FEAT: Add mandatory verification step to Pedro
- REFACTOR: Update verification to check only added commits
- CHORE: Add gitignore rules and update CHANGELOG

### v1.0.1 (2025-10-25)
**PR #2: Config System, Dynamic Wrappers, and Unified Setup**
- FEAT: Add automated setup script with pre-flight checks and dynamic wrapper generation
- FEAT: Add observability configuration system with .observability-config and state files
- FEAT: Add bash config loader utility for shell scripts
- REFACTOR: Move all hooks to .claude/hooks/observability/ subdirectory
- REFACTOR: Update hardcoded paths to use config-based paths
- DOCS: Complete overhaul with unified setup guide and architecture documentation
- DOCS: Add initial CHANGELOG.md file
- CHORE: Standardize script names with observability-* prefix

### v1.0.0 (2025-10-20)
**PR #1: Initial Infrastructure and Workflow Enhancements**
- FEAT: Add Kim agent for observability system management
- FEAT: Add theme system with custom theme creation and import/export
- FEAT: Add human-in-the-loop WebSocket system for agent interactions
- FEAT: Add user preferences management with SQLite backend and REST API
- FEAT: Add summary generation UI with client-side button and workflow
- FIX: Add .env file protection with access rules in pre-tool-use hook
- FIX: Add SSH key integration via git-ai.sh script with keychain support
- DOCS: Add git-ai.sh usage instructions and Mark agent policy to CLAUDE.md

## Progress

### [x] Completed Core Infrastructure
- [x] Multi-agent observability system with real-time WebSocket streaming
- [x] SQLite database with automatic migrations and WAL mode
- [x] Vue 3 dashboard with dual-color system (app + session colors)
- [x] Live pulse chart with session-colored bars and event type indicators
- [x] Hook system for all Claude Code lifecycle events
- [x] Python-based event processing with Astral uv
- [x] Automated setup script with comprehensive overwrite warnings
- [x] Configuration system with .observability-config and state files
- [x] Dynamic wrapper generation for project integration

### [x] Completed AI Agent System
- [x] Jerry (summary-processor) - On-demand AI summaries with Haiku 4.5
- [x] Mark (ghcli) - GitHub operations with provenance tracking
- [x] Pedro (changelog-manager) - CHANGELOG maintenance with verification
- [x] Atlas (primer-generator) - Context and architecture documentation
- [x] Bixby (html-converter) - HTML formatting with LearnStreams styling
- [x] Kim (deprecated but available) - Observability system management

### [x] Completed Features
- [x] Real-time and on-demand summary generation
- [x] Human-in-the-loop (HITL) WebSocket system
- [x] TTS notifications (ElevenLabs, OpenAI, pyttsx3)
- [x] Theme system with dark/light mode and custom themes
- [x] Multi-criteria filtering (app, session, event type)
- [x] Chat transcript viewer with syntax highlighting
- [x] Git helper with AI attribution (git-ai.sh)
- [x] User preferences with SQLite backend
- [x] Session tracking and management
- [x] Meta-event detection for summary operations
- [x] Project registration with database persistence
- [x] One-button summary generation workflow

### [ ] Current Working State
- [ ] 5 untracked files/directories in working tree:
  - .ai/context_engineering.md (new documentation file)
  - .ai/prd/ (new directory for product requirements)
  - .ai/prp/ (new directory for project roadmap/planning)
  - .ai/scratch/ (generated primers and working files)
  - .claude/commands/convert-to-planning.md (new command)
- [ ] No staged changes
- [ ] No uncommitted modifications to tracked files
- [ ] Branch: main (up to date with origin)

## Next Steps

### Evaluate New Structure
- [ ] Review .ai/ directory organization
  - context_engineering.md - Document purpose and usage
  - prd/ - Product requirements documentation
  - prp/ - Project roadmap and planning
- [ ] Evaluate convert-to-planning.md command functionality
- [ ] Consider if new directories should be tracked or gitignored

### Ongoing Maintenance
- [ ] Keep CHANGELOG updated via Pedro agent
- [ ] Monitor hook performance and optimize as needed
- [ ] Review and update AI agent instructions based on usage
- [ ] Ensure all documentation stays synchronized
- [ ] Test setup script with new overwrite warnings

### Potential Enhancements
- [ ] Consider additional slash commands for common workflows
- [ ] Evaluate new agent types for specialized tasks
- [ ] Optimize database queries for performance
- [ ] Expand filter options in dashboard
- [ ] Consider additional HITL features

## System Architecture

### Core Components
```
Claude Agents → Hook Scripts → HTTP POST → Bun Server → SQLite → WebSocket → Vue Client
```

### Directory Structure
```
.claude/
├── agents/ (Specialized AI agents)
│   ├── summary-processor.md (Jerry - Haiku 4.5)
│   ├── changelog-manager.md (Pedro - CHANGELOG mgmt)
│   ├── html-converter.md (Bixby - MD to HTML)
│   ├── primer-generator.md (Atlas - Context/arch)
│   └── ghcli.md (Mark - GitHub operations)
├── commands/ (Custom slash commands)
│   ├── generate-context.md, generate-arch.md
│   ├── prime-quick.md, prime-full.md
│   ├── process-summaries.md
│   ├── o-start/stop/status/enable/disable.md
│   ├── quick-plan.md, build.md
│   ├── convert_paths_absolute.md, load_ai_docs.md
│   └── convert-to-planning.md (NEW)
├── hooks/observability/
│   ├── send_event.py (Core event sender)
│   ├── session_start.py, session_end.py
│   ├── pre_tool_use.py, post_tool_use.py
│   ├── notification.py, stop.py, subagent_stop.py
│   ├── user_prompt_submit.py, pre_compact.py
│   └── utils/ (LLM, TTS, HITL, config)
├── settings.json (Hook configuration)
├── .observability-state (enabled/disabled)
└── .observability-config (gitignored)

apps/
├── server/ (Bun TypeScript server - port 4000)
│   ├── src/
│   │   ├── index.ts (HTTP/WebSocket endpoints)
│   │   ├── db.ts (SQLite management)
│   │   └── types.ts
│   ├── data/ (SQLite database - gitignored)
│   └── logs/ (Server logs - gitignored)
└── client/ (Vue 3 TypeScript client - port 5173)
    ├── src/
    │   ├── App.vue (Main app + theme + WebSocket)
    │   ├── components/ (EventTimeline, FilterPanel, ChatTranscriptModal, LivePulseChart)
    │   ├── composables/ (useWebSocket, useEventColors, useChartData)
    │   └── types.ts
    └── logs/ (Client logs - gitignored)

scripts/
├── observability-*.sh (System control)
└── git-ai.sh (Git with AI attribution)

.ai/
├── docs/ (Fetched API documentation)
├── prd/ (NEW - Product requirements)
├── prp/ (NEW - Project roadmap/planning)
├── scratch/ (Generated primers - gitignored)
└── context_engineering.md (NEW)

templates/
└── *.template (Config templates)
```

### Data Flow
1. Claude Code executes action (tool use, notification, etc.)
2. Hook script runs based on settings.json configuration
3. Hook gathers context (tool name, inputs, outputs, session ID)
4. send_event.py sends JSON payload to server via HTTP POST
5. Server validates, stores in SQLite, broadcasts to WebSocket clients
6. Vue app receives event and updates timeline in real-time

### Event Types
- **PreToolUse** (🔧): Before tool execution
- **PostToolUse** (✅): After tool completion
- **Notification** (🔔): User interactions
- **Stop** (🛑): Response completion with chat transcript
- **SubagentStop** (👥): Subagent finished
- **PreCompact** (📦): Context compaction
- **UserPromptSubmit** (💬): User prompt submission (v1.0.54+)
- **SessionStart** (🚀): Session started
- **SessionEnd** (🏁): Session ended

### Unique Agent Identification
- Format: source_app:session_id
- Display: source_app:session_id (first 8 chars)
- Example: multi-agent-workflow:c23d221b

## Specialized Agents

### Jerry (Summary Processor)
- **Purpose**: On-demand AI summaries for hook events
- **Model**: Claude Haiku 4.5
- **Tools**: Bash (database updates)
- **Trigger**: /process-summaries command
- **Color**: Orange
- **Format**: One sentence, technical, present tense, <15 words
- **Workflow**:
  1. User clicks "Generate Summaries" button
  2. System saves prompt to .summary-prompt.txt
  3. User runs /process-summaries
  4. Jerry generates summaries and updates database

### Mark (GitHub Operations Manager)
- **Purpose**: ALL GitHub CLI operations with provenance tracking
- **Model**: Configurable (main session)
- **Tools**: Bash (git only), Read
- **Restrictions**: No file writes, no SSH, no direct gh commands
- **Workflow**: Dispatches .github/workflows/gh-dispatch-ai.yml
- **Operations**: pr-create, pr-comment, issue-comment
- **Provenance**: Always Claude_AI with session ID

### Pedro (Changelog Manager)
- **Purpose**: CHANGELOG maintenance with verification
- **Model**: Configurable
- **Tools**: Read, Write, Bash
- **Features**: Duplicate detection, version ordering, commit linking
- **Exception**: Read-only gh release view access
- **Verification**: Checks only newly added commits

### Atlas (Primer Generator)
- **Purpose**: Generate context and architecture documentation
- **Model**: Haiku
- **Tools**: Bash, Read, Write, Glob, Grep, SlashCommand
- **Color**: Green
- **Outputs**: context-primer.md, arch-primer.md in .ai/scratch/
- **Commands**: /prime-full, /prime-quick, /generate-context, /generate-arch
- **Workflow**:
  1. Reads CHANGELOG.md for recent history
  2. Runs git commands for current state
  3. Executes /generate-context and /generate-arch
  4. Generates primers (gitignored, fresh per developer)

### Bixby (HTML Converter)
- **Purpose**: Convert markdown/text to styled HTML
- **Model**: Haiku
- **Tools**: Read, Write
- **Color**: Purple
- **Features**: Dark mode, collapsible TOC, LearnStreams styling
- **Note**: Formatter only, NOT content creator
- **Triggers**: "Convert [file] to HTML", "Format [file] as HTML"

## Available Commands

### Observability Control
- `/o-start` - Start observability system (server + client)
- `/o-stop` - Stop observability system
- `/o-status` - Check system status
- `/o-enable` - Enable event streaming
- `/o-disable` - Disable event streaming

### Agent Operations
- `/process-summaries` - Generate on-demand summaries via Jerry
- `/prime-full` - Generate fresh primers via Atlas (10-30s)
- `/prime-quick` - Read existing primers (fast, <5s)
- `/generate-context` - Generate context-primer.md
- `/generate-arch` - Generate arch-primer.md

### Utilities
- `/quick-plan [prompt]` - Create implementation plans
- `/build [path-to-plan]` - Build based on plan
- `/convert_paths_absolute` - Convert relative paths in settings.json
- `/load_ai_docs` - Load documentation from websites
- `/convert-to-planning` - NEW command (purpose to be documented)

## Configuration

### Environment Variables (.env)
Place in TWO locations:
1. Project root (.env) - For Python hooks
2. Server directory (apps/server/.env) - For Bun server

Variables:
- `ANTHROPIC_API_KEY` - Claude API (required for real-time summaries)
- `ENGINEER_NAME` - Your name (optional, for TTS)
- `OPENAI_API_KEY` - OpenAI API (optional, for TTS)
- `ELEVENLABS_API_KEY` - ElevenLabs API (optional, for TTS)
- `ELEVENLABS_VOICE_ID` - Voice ID (optional, defaults to Adam)
- `GEMINI_API_KEY` - Google Gemini API (optional)

### Observability Config (.claude/.observability-config)
```json
{
  "MULTI_AGENT_WORKFLOW_PATH": "/absolute/path/to/multi-agent-workflow",
  "SERVER_URL": "http://localhost:4000",
  "CLIENT_URL": "http://localhost:5173",
  "PROJECT_NAME": "auto-detected"
}
```

### Observability State (.claude/.observability-state)
- `enabled` / `disabled` (controls event streaming)
- No restart needed when toggling

## Tech Stack

### Server
- Runtime: Bun
- Language: TypeScript
- Database: SQLite (bun:sqlite) with WAL mode
- WebSocket: Built-in Bun support
- Port: 4000

### Client
- Framework: Vue 3
- Language: TypeScript
- Build: Vite
- Styling: Tailwind CSS
- Port: 5173

### Hooks
- Language: Python 3.8+
- Package Manager: Astral uv
- LLMs: Anthropic Claude, OpenAI
- TTS: ElevenLabs, OpenAI, pyttsx3
- Media Player: mpv

## Git Workflow

### Commit Messages
- Format: <60 chars, brief, imperative mood
- Example: "Add feature X" not "Added feature X"

### SSH Git Commands
- ALWAYS use `./scripts/git-ai.sh` for SSH operations
- Commands: commit, push, pull, fetch, clone, remote, ls-remote, submodule
- Benefits: SSH keychain integration, AI attribution, provenance metadata
- Example: `./scripts/git-ai.sh commit -m "message"`

### GitHub Operations
- ALL write operations through Mark agent
- Read-only exception: Pedro can use `gh release view`
- Provenance: Always Claude_AI with session ID and timestamp
- Workflow: Mark dispatches .github/workflows/gh-dispatch-ai.yml

## Summary System

### Real-time Mode
- Automatic summaries as events occur
- Uses Anthropic API via Python hooks
- Requires ANTHROPIC_API_KEY
- Cost: ~few cents per 10 summaries
- Best for: Active monitoring
- Enable in Settings tab

### On-Demand Mode (Recommended)
- Manual via "Generate Summaries" button
- Uses Jerry subagent (Haiku 4.5)
- No API key required
- Best for: Cost savings, occasional reviews
- Workflow:
  1. Click button → creates .summary-prompt.txt
  2. Run /process-summaries
  3. Jerry reads events and generates summaries
  4. Database updated, GUI reflects changes

### Meta-Events
- Summary processing operations tagged with [Meta-event: prefix
- Styled with orange background
- Easy identification of Jerry's work

## Server Endpoints

### HTTP REST
- `POST /events` - Receive events from hooks
- `GET /events/recent` - Paginated event retrieval with filtering
- `GET /events/filter-options` - Available filter values
- `POST /events/batch-summaries` - Update summaries in batch
- `POST /projects/register` - Register project path
- `POST /hitl/response` - Human-in-the-loop responses
- `GET /themes` - List available themes
- `POST /themes` - Create custom theme
- `GET /themes/:name` - Get specific theme
- `DELETE /themes/:name` - Delete theme
- `POST /themes/:name/activate` - Activate theme
- `GET /user-preferences` - Get user preferences
- `PUT /user-preferences` - Update preferences

### WebSocket
- `WS /stream` - Real-time event broadcasting
- Sends events to all connected clients
- Client auto-reconnect on disconnect

## Database Schema

### Events Table
- id (INTEGER PRIMARY KEY)
- timestamp (TEXT)
- source_app (TEXT)
- session_id (TEXT)
- hook_event_type (TEXT)
- payload (TEXT JSON)
- chat (TEXT JSON, optional)
- summary (TEXT, optional)

### Projects Table
- id (INTEGER PRIMARY KEY)
- name (TEXT UNIQUE)
- path (TEXT)
- first_seen (TEXT)
- last_activity (TEXT)
- event_count (INTEGER)

### Themes Table
- id (INTEGER PRIMARY KEY)
- name (TEXT UNIQUE)
- colors (TEXT JSON)
- is_active (INTEGER)
- is_default (INTEGER)
- created_at (TEXT)

### UserPreferences Table
- id (INTEGER PRIMARY KEY)
- key (TEXT UNIQUE)
- value (TEXT)
- updated_at (TEXT)

### Indexes
- idx_events_timestamp
- idx_events_session
- idx_events_type
- idx_events_app

## Integration with Other Projects

### Setup Process
1. Run `observability-setup.sh . [PROJECT_NAME]`
2. Shows comprehensive overwrite warnings (v1.0.5)
3. Creates .claude/ directory with hooks and configuration
4. Generates wrapper scripts in ./scripts/
5. Creates .observability-config with path to this repo
6. Updates .gitignore with observability entries
7. Merges with existing settings.json if present

### Shared Architecture
- All projects send events to this repo's server
- Single SQLite database for all projects
- Dashboard displays events from all integrated projects
- Projects depend on this repo (critical dependency)

### Recovery
- If repo moved: Update .observability-config in each project
- If repo deleted: Re-clone and re-run setup
- To disconnect: Remove hooks from settings.json

## Security Features

### Pre-Tool-Use Hook
- Blocks dangerous commands (rm -rf, etc.)
- Prevents access to sensitive files (.env, private keys)
- Validates all inputs before execution
- No external dependencies for core functionality

### File Protection
- .env files gitignored
- .observability-config gitignored (environment-specific)
- .observability-state gitignored
- Session data in logs/ gitignored
- .ai/scratch/ gitignored (generated primers)

## Notes

### Critical Dependencies
- This repo must remain at fixed location for integrated projects
- Server must be running for observability to work
- Hooks require Astral uv and Python 3.8+
- SSH operations require git-ai.sh script
- Bun required for server (not npm/yarn)

### Client Features
- Real-time WebSocket updates
- Multi-criteria filtering (app, session, event type)
- Live pulse chart with session-colored bars
- Time range selection (1m, 3m, 5m)
- Chat transcript viewer with syntax highlighting
- Auto-scroll with manual override
- Dark/light theme support with custom themes
- Event limiting (configurable via VITE_MAX_EVENTS_TO_DISPLAY)

### Why Primers Are Gitignored
- Generated fresh per developer - always current
- No git noise from frequent updates
- No merge conflicts between developers
- Personal to each developer's workflow
- Atlas regenerates as needed

### When to Use Atlas
- **First time in repo**: Run /prime-full to generate primers
- **Start of work session**: Run /prime-quick for instant context
- **After major changes**: Regenerate with /prime-full
- **Switching branches**: Regenerate to reflect new context

### HITL (Human-in-the-Loop)
- Real-time interaction between agent and user
- WebSocket-based communication
- Dashboard-based approval/denial
- Timeout support
- Session-aware
- Core implementation: .claude/hooks/observability/utils/hitl.py

### Development Best Practices
- Prefer slash commands over improvised tool calls
- Use absolute file paths (not relative)
- Follow commit message format (<60 chars, imperative)
- Test hooks with curl before deploying
- Monitor dashboard for event flow
- Always use git-ai.sh for SSH operations
- Never call gh directly (use Mark agent)
