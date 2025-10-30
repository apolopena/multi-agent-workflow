# Architecture Primer: Multi-Agent Workflow System

## System Overview

**Multi-Agent Workflow** is a complete AI-powered development platform with real-time observability, automated GitHub operations, and intelligent git tooling. It enables multiple Claude Code agents to work in parallel with centralized monitoring and coordination.

## Core Architecture

```
Claude Code Agents (Projects)
        ↓ (HTTP POST JSON)
Hook Scripts (Python + uv)
        ↓ (event_data)
Bun Server (TypeScript)
    ├── SQLite Database
    ├── HITL System (WebSocket to Agents)
    └── WebSocket Broadcaster
        ↓
Vue 3 Client (Dashboard)
    └── Real-time Event Timeline
```

## Key Design Patterns

### 1. Hook System (Event Interception)
**Pattern**: Observer with event classification

- **Entry Point**: Claude Code lifecycle hooks
- **Configuration**: `.claude/settings.json` defines hook execution
- **Implementation**: Python scripts using Astral `uv` for dependency management
- **Data Format**: JSON with standard envelope (source_app, session_id, hook_event_type, payload)
- **Transport**: HTTP POST to central server

**Hook Types**:
```
session_start.py ──┐
pre_tool_use.py ───┤
post_tool_use.py ──┤
notification.py ───├──> send_event.py ──> Server
stop.py ───────────┤
user_prompt_submit ┤
subagent_stop.py ──┘
```

**Key Features**:
- Pre-flight validation (blocking dangerous commands)
- Context attachment (--add-chat for full conversation)
- Graceful degradation (silent failures if server unavailable)
- Meta-event detection (Jerry operations tagged with [Meta-event:])

### 2. Configuration System
**Pattern**: Runtime environment-specific configuration

**Files**:
- `.observability-config` (gitignored) - Environment paths and URLs
- `.observability-state` - Single line: "enabled" or "disabled"
- `settings.json` (in .claude/) - Hook command definitions

**Dynamic Loading**:
- Hooks load config at runtime via `load-config.sh` bash utility
- No hardcoded paths - all configurable
- Setup script generates wrappers with back-references to main repo

**Example Wrapper Flow**:
```
Project/.claude/hooks/send_event.py
    ↓ (imports config)
Project/.claude/.observability-config
    ↓ (reads MULTI_AGENT_WORKFLOW_PATH)
~/multi-agent-workflow/scripts/
    ↓ (central management scripts)
~/multi-agent-workflow/apps/server/
```

### 3. Server Architecture (Bun TypeScript)

**Components**:

#### HTTP Server
- Port 4000 (configurable)
- Routes:
  - `POST /events` - Receive hook events
  - `GET /events/recent` - Paginated retrieval with filters
  - `GET /events/filter-options` - Dynamic filter values
  - `POST /events/batch-summaries` - Update summaries (Jerry)
  - `POST /projects/register` - Register project paths
  - `POST /hitl/response` - HITL responses from dashboard

#### Database Layer
- **Database**: SQLite with WAL mode (concurrent access)
- **Schema**: events table with auto-migrations
- **Features**:
  - Automatic timestamp indexing
  - Chat transcript storage
  - Summary caching
  - HITL response tracking

**Database Design**:
```
events (
  id INTEGER PRIMARY KEY,
  source_app TEXT,
  session_id TEXT,
  hook_event_type TEXT,
  timestamp DATETIME,
  payload JSON,
  summary TEXT,
  hitl_question TEXT,
  hitl_response TEXT
)

themes (theme storage)
settings (user preferences)
projects (project registry)
```

#### WebSocket Broadcasting
- Endpoint: `WS /stream`
- Purpose: Real-time event delivery to all connected clients
- Format: JSON event envelope (same as HTTP POST)
- Features:
  - Multiple client support
  - Automatic connection cleanup
  - Broadcast to all on new event

#### HITL System Integration
- Bidirectional WebSocket to agent process
- Flow:
  1. Dashboard receives HITL question via normal event
  2. User responds via dialog
  3. Server sends response back to agent via WebSocket
  4. Agent receives approval/denial and continues

**HITL Response Handler**:
```typescript
POST /hitl/response
body: { event_id, hitl_response, approved }
1. Lookup event in database
2. Connect to agent's HITL WebSocket
3. Send response
4. Update event in database
5. Broadcast updated event to clients
```

### 4. Client Architecture (Vue 3)

**Structure**:
```
App.vue (Main component + WebSocket management)
├── composables/
│   ├── useWebSocket.ts (Connection + auto-reconnect)
│   ├── useEventColors.ts (App color assignment)
│   ├── useEventEmojis.ts (Type → emoji mapping)
│   └── useChartData.ts (Time-series aggregation)
├── components/
│   ├── EventTimeline.vue (Main timeline view)
│   ├── EventRow.vue (Individual event display)
│   ├── FilterPanel.vue (Multi-select filters)
│   ├── ChatTranscriptModal.vue (Full conversation viewer)
│   ├── LivePulseChart.vue (Real-time activity chart)
│   └── StickScrollButton.vue (Scroll control)
└── utils/
    └── chartRenderer.ts (Canvas-based rendering)
```

**Visual Design**:
- **Dual Border System**:
  - Left border: App color (source_app)
  - Second border: Session color (session_id)
  - Enables visual distinction at a glance

- **Event Display**:
  - Emoji + type name + timestamp
  - Payload displayed as formatted JSON/text
  - Summaries shown on right side (if available)
  - HITL questions highlighted in yellow

- **Live Pulse Chart**:
  - Canvas-based real-time rendering
  - Time range: 1m, 3m, 5m selectable
  - Session-colored bars
  - Event type emojis overlaid
  - Smooth animations + glow effects

**Theme System**:
- Dark mode by default (toggle available)
- Custom theme creation and import/export
- Persistence via localStorage

### 5. Agent Dispatch System

**Agents**: Specialized subagents for specific workflow tasks

#### Jerry (Summary Processor)
**Type**: `subagent_type=haiku`
**Trigger**: User says "Process summaries from .summary-prompt.txt"
**Workflow**:
1. Read `.summary-prompt.txt` (GUI creates this)
2. Parse event list
3. Generate summaries (strict format rules)
4. Curl POST batch to `/events/batch-summaries`
5. Report results

**Summary Rules**:
- ONE sentence only (no period)
- <15 words
- Present tense
- Focus on KEY action
- Technical and specific

**Auto-Dispatch**: Built into command definition

#### Pedro (Changelog Manager)
**Type**: changelog management
**Features**:
- Reads git history from current branch
- Parses PR information
- Mandatory verification step
- Checks only newly added commits

#### Mark (GitHub Operations)
**Type**: `subagent_type=mark`
**Restriction**: ALL GitHub operations must go through Mark
**Workflow**:
1. Gather context from working directory
2. Dispatch `.github/workflows/gh-dispatch-ai.yml`
3. Workflow executes with provenance metadata
4. Results logged with full attribution

**Why Mark?**
- Provenance tracking (Claude_AI attribution)
- SSH handling (no auth errors)
- Audit trail (centralized logging)
- Prevents direct `gh` CLI calls from other agents

#### Atlas (Primer Generator)
**Type**: `subagent_type=haiku`
**Commands**:
- `/generate-context` - Create context-primer.md
- `/generate-arch` - Create arch-primer.md
- `/prime-quick` - Read existing primers (fast)
- `/prime-full` - Generate fresh (slower, ~10-30s)

#### Bixby (HTML Converter)
**Type**: Markdown/text to HTML formatter
**Trigger**: "Convert [file] to HTML"
**Restriction**: Formatter only, not content creator

### 6. Session Identification

**Pattern**: source_app + session_id for unique agent tracking

**Display Format**: `source_app:session_id[:8]` (truncate session_id)

**Assigned By**: Claude Code on session start (immutable within session)

**Uses**:
- Color assignment (each session gets unique color)
- Event filtering
- HITL routing (responses sent back to specific session)
- Subagent identification

### 7. Event Data Model

**Standard Event Envelope**:
```json
{
  "source_app": "project-name",
  "session_id": "uuid-or-id",
  "hook_event_type": "PreToolUse|PostToolUse|Stop|...",
  "timestamp": "2025-10-29T14:30:45Z",
  "payload": {
    // Event-specific data (tool_name, tool_input, results, etc.)
  },
  "summary": "Optional: Jerry-generated summary",
  "hitl_question": "Optional: HITL question for user",
  "hitl_response": "Optional: User's response (true/false)",
  "chat": "Optional: Full conversation transcript (if --add-chat)"
}
```

**Event Type Summary**:
```
PreToolUse        → Tool validation (can block)
PostToolUse       → Tool result capture
UserPromptSubmit  → User prompt logging
Notification      → User interaction points
SessionStart      → Session initialization
SessionEnd        → Session cleanup
Stop              → Response completion with summary
SubagentStop      → Subagent task end
PreCompact        → Context compaction tracking
```

### 8. Security & Validation

**Hook-Level** (pre_tool_use.py):
- Blocks dangerous commands (rm -rf, etc.)
- Prevents sensitive file access (.env, keys)
- Validates tool input before execution

**Server-Level**:
- Event schema validation
- Timestamp verification
- Session ID validation
- HITL timeout (60 seconds)

**Project-Level**:
- Setup script warnings and backups
- Config verification
- Git status display in status bar

### 9. Integration Workflow

**Setup Process**:
1. Run `observability-setup.sh` in target project
2. Script detects existing `.claude/` configuration
3. Creates/updates hooks, agents, commands
4. Generates `.observability-config` with dynamic paths
5. Creates wrapper scripts in project's `./scripts/`
6. Updates `.gitignore`

**Why Wrappers?**:
- Decouple project from central repo paths
- Enable moving/reinstalling central repo
- Allow project-specific customization
- Shared server instance across projects

**Critical Dependency**:
- All projects reference central server (http://localhost:4000)
- If repo moved: Update `.observability-config` in each project
- If repo deleted: Requires re-setup or server migration

### 10. Technology Stack

**Backend**:
- **Runtime**: Bun (JavaScript/TypeScript)
- **Server**: Bun.serve() with HTTP + WebSocket
- **Database**: SQLite (bun:sqlite)
- **Language**: TypeScript

**Frontend**:
- **Framework**: Vue 3 (composition API)
- **Language**: TypeScript
- **Build**: Vite
- **Styling**: Tailwind CSS
- **Charts**: Canvas API (custom renderer)

**Hooks/Integration**:
- **Language**: Python 3.8+
- **Package Manager**: Astral uv (embedded in scripts)
- **LLM**: Anthropic Claude (SDK), OpenAI (fallback)
- **TTS**: ElevenLabs, OpenAI, pyttsx3
- **Communication**: HTTP REST, WebSocket (JSON)

## Data Flow Sequences

### 1. Normal Event Capture
```
Claude Code Action
    ↓
Hook Script Triggered
    ↓
Gather Context (tool_name, input, output, etc.)
    ↓
send_event.py (construct JSON envelope)
    ↓
HTTP POST to Server:4000/events
    ↓
Server validates + stores in SQLite
    ↓
WebSocket broadcast to all clients
    ↓
Vue Client receives + renders in timeline
```

### 2. HITL (Human-in-the-Loop) Response
```
Hook Script (pre_tool_use) detects requires-permission scenario
    ↓
Constructs HITL question in event
    ↓
POST to Server (includes hitl_question field)
    ↓
Server broadcasts to clients
    ↓
Vue Client shows dialog
    ↓
User responds (approve/deny)
    ↓
Client POSTs to /hitl/response
    ↓
Server connects to agent's HITL WebSocket
    ↓
Server sends response message
    ↓
Agent receives approval/denial
    ↓
Agent continues execution (or stops)
```

### 3. Summary Generation (Jerry)
```
User clicks "Generate Summaries" in GUI
    ↓
Vue Client creates .summary-prompt.txt file
    ↓
User runs /process-summaries command
    ↓
Jerry subagent dispatched (Haiku 4.5)
    ↓
Jerry reads .summary-prompt.txt
    ↓
Generates summaries (strict format)
    ↓
Curl POSTs batch to /events/batch-summaries
    ↓
Server updates database
    ↓
Server broadcasts updated events
    ↓
Vue Client refreshes summaries in timeline
```

### 4. GitHub Operations (Mark)
```
User requests: "Create PR for feature X"
    ↓
Main Agent dispatches Mark subagent
    ↓
Mark gathers context (git status, diffs, etc.)
    ↓
Mark calls gh CLI via dispatcher workflow
    ↓
Workflow creates PR with provenance metadata
    ↓
PR tagged with Claude_AI attribution
    ↓
Mark reports results to main agent
```

## Performance Characteristics

**Event Throughput**:
- Typical: 10-50 events/minute (during active coding)
- Peak: 100+ events/minute (rapid tool execution)
- Storage: ~500 bytes per event (JSON)

**Database**:
- WAL mode: Supports concurrent reads + writes
- Index on timestamp: Fast time-range queries
- Auto-cleanup: Configurable (keep last N events)

**WebSocket**:
- Broadcast latency: <100ms to all clients
- Max clients: Limited by system resources
- Reconnection: Automatic with exponential backoff

**Client Performance**:
- Max display: Configurable (default 100 events)
- Live chart: Updates every 100ms
- Memory: Grows with event count (cleanup available)

## Error Handling & Resilience

**Server Unavailable**:
- Hooks detect server connection failure
- Events not sent (logged to local file if configured)
- Agent continues normally (non-blocking)

**Database Corruption**:
- WAL mode recovers gracefully
- Auto-migration on schema changes
- No data loss on power loss (WAL benefits)

**WebSocket Disconnect**:
- Client auto-reconnects every 3 seconds
- Fetches missed events via REST on reconnect
- No data loss (all events stored in database)

**HITL Timeout**:
- 60-second timeout on user response
- Timeout = auto-deny response
- Agent receives timeout message and handles gracefully

## Extension Points

**Adding New Event Types**:
1. Add hook script (e.g., `my_event.py`)
2. Define in settings.json
3. Update constants.py with emoji mapping
4. Add display component in Vue if needed

**Adding New Agents**:
1. Create agent `.md` file in `.claude/agents/`
2. Define in agent format (name, description, model, color, tools)
3. Auto-dispatch via command definition

**Custom Visualization**:
1. Add composable (e.g., `useCustomChart.ts`)
2. Add component (e.g., `CustomChart.vue`)
3. Integrate into `App.vue`

## Deployment Considerations

**Single Instance** (recommended):
- One central server instance
- Multiple projects share same database
- Reduced infrastructure overhead
- Centralized monitoring

**Multi-Instance** (advanced):
- Each project has own server
- Separate databases
- No cross-project visibility
- More operational overhead

**Production Features**:
- Database backup (automatic via WAL)
- Event retention policies (configurable)
- Access control (via HTTP auth middleware)
- Rate limiting (per source_app)
