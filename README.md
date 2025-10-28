# Multi-Agent Workflow System

A complete AI-powered development workflow featuring real-time agent observability, automated GitHub operations with provenance tracking, AI-generated summaries, and intelligent git helper tooling.

> **Note**: This is a fork and extension of [claude-code-hooks-multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability) by [@disler](https://github.com/disler). The original project provided the foundational observability system. This fork extends it into a complete workflow system with automated GitHub operations, AI agents (Jerry & Mark), git helper tooling, and enhanced summary capabilities. Full credit to the original author for the excellent foundation. You can watch the [original breakdown here](https://youtu.be/9ijnN985O_c) and the latest enhancement comparing Haiku 4.5 and Sonnet 4.5 [here](https://youtu.be/aA9KP7QIQvM).

## 🎯 Overview

This is a **complete workflow system** for AI-assisted development, not just an observability tool. It provides:

- **Multi-Agent Observability**: Real-time monitoring and visualization of Claude Code agent behavior through comprehensive hook event tracking
- **Automated GitHub Operations**: AI-powered PR creation, issue management, and comments with full provenance tracking
- **AI-Generated Summaries**: Real-time or on-demand event summaries with meta-event detection
- **Git Helper with Attribution**: Automated git operations with AI attribution and provenance metadata
- **TTS Notifications**: Voice announcements for agent completion and important events
- **Session Management**: Track multiple concurrent agents with session tracking, event filtering, and live updates 

<img src="images/app.png" alt="Multi-Agent Observability Dashboard" style="max-width: 800px; width: 100%;">

## 🏗️ Architecture

```
Claude Agents → Hook Scripts → HTTP POST → Bun Server → SQLite → WebSocket → Vue Client
```

![Agent Data Flow Animation](images/AgentDataFlowV2.gif)

## 📋 Prerequisites

- **Node.js** - JavaScript runtime (install via your preferred method: nvm, apt, brew, etc.)
- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** - Anthropic's official CLI for Claude
- **[Astral uv](https://docs.astral.sh/uv/)** - Fast Python package manager (required for hook scripts)
- **[Bun](https://bun.sh/)**, **npm**, or **yarn** - For running the server and client
- **[jq](https://jqlang.github.io/jq/)** - JSON processor (`sudo apt install jq`)
- **[mpv](https://mpv.io/)** - Media player for TTS audio (`sudo apt install mpv` on Linux)
- **Anthropic API Key** - Add to `.env` as `ANTHROPIC_API_KEY` (for real-time summaries)
- **OpenAI API Key** (optional) - Add to `.env` for TTS and completion messages
- **ElevenLabs API Key** (optional) - Add to `.env` for TTS notifications

**Here's a one-liner to install all the items, assuming you have Node already installed:**

```bash
curl -fsSL https://bun.sh/install | bash && curl -LsSf https://astral.sh/uv/install.sh | sh && sudo apt install -y jq mpv
```

## 🚨 Important: Shared System Architecture

**This repository provides a centralized observability server and client that ALL integrated projects depend on.**

### How It Works

When you integrate observability into your projects:
- Your project copies hook scripts that send events to this repo's server (`http://localhost:4000`)
- Wrapper scripts in your project call back to management scripts in this repo
- All projects share a single server instance and SQLite database
- The client dashboard (`http://localhost:5173`) displays events from all integrated projects

### Critical Dependencies

⚠️ **Your integrated projects will break if:**
- This repository is moved or deleted
- The server is not running (`./scripts/start-system.sh`)
- The repository path changes without updating configs

### Recovery Options

If this repo is moved/deleted, your integrated projects will show errors. To recover:

1. **If repo moved**: Update `.claude/.observability-config` in each project with new path
2. **If repo deleted**: Clone this repo again and re-run setup scripts
3. **To disconnect**: Remove observability hooks from `.claude/settings.json` in your projects

### Alternative: Custom Server Instance

To run an independent server for a specific project:
1. Clone this repo to a project-specific location
2. Modify `SERVER_URL` in `.claude/.observability-config`
3. Run your own server instance with custom port

## ⚙️ Setup: Integrate Observability Into Your Projects

### Option 1: New Project (No Existing .claude Configuration)

**Quick setup for projects without Claude Code configuration:**

```bash
# 1. Clone this repo (if not already done)
git clone <this-repo-url> ~/multi-agent-workflow
cd ~/multi-agent-workflow

# 2. Navigate to your project
cd /path/to/your/project

# 3. Run automated setup
~/multi-agent-workflow/scripts/observability-setup.sh . [PROJECT_NAME]

# 4. Restart Claude Code to load new configuration

# 5. Start the observability server (from multi-agent-workflow directory)
cd ~/multi-agent-workflow
./scripts/start-system.sh

# 6. Open dashboard and start coding
# Dashboard: http://localhost:5173
```

**What this does:**
- Creates `.claude/` directory with hooks, agents, commands, and status lines
- Generates wrapper scripts in `./scripts/` that call back to multi-agent-workflow
- Creates `.claude/.observability-config` with path to multi-agent-workflow repo
- Updates `.gitignore` with observability entries
- Auto-detects project name from git (or uses provided name)

### Option 2: Existing Project (With .claude Configuration)

**Setup for projects with existing Claude Code configuration:**

```bash
# 1. From your project directory
cd /path/to/your/project

# 2. Run automated setup (will merge with existing settings)
/path/to/multi-agent-workflow/scripts/observability-setup.sh . [PROJECT_NAME]
```

**What happens:**
- ⚠️ **Backup created**: `settings.json.TIMESTAMP` before any changes
- ⚠️ **Overwrites**: `hooks`, `statusLine`, and `includeCoAuthoredBy` sections
- ✅ **Preserves**: Your custom agents, commands, permissions, and other settings
- Script shows warnings and asks for confirmation before proceeding

### Managing Observability

**Via Kim Agent** (if installed):
```
"Kim, start the observability server"
"Kim, check observability status"
"Kim, disable event streaming"
"Kim, enable event streaming"
```

**Via Scripts** (from any integrated project):
```bash
# Check status (server + event streaming)
./scripts/observability-status.sh

# Enable/disable event streaming (no restart needed)
./scripts/observability-enable.sh
./scripts/observability-disable.sh

# Start/stop server (run from multi-agent-workflow directory)
cd ~/multi-agent-workflow
./scripts/start-system.sh
./scripts/stop-system.sh
```

### Configuration Files

After setup, your project will have:

**`.claude/.observability-config`** (gitignored, environment-specific):
```json
{
  "MULTI_AGENT_WORKFLOW_PATH": "/absolute/path/to/multi-agent-workflow",
  "SERVER_URL": "http://localhost:4000",
  "CLIENT_URL": "http://localhost:5173"
}
```

**`.claude/.observability-state`** (gitignored):
```
enabled  # or 'disabled'
```

### Verifying Installation

```bash
# 1. Check server is running
curl http://localhost:4000/events/recent

# 2. Run any Claude Code command in your project
# Example: "list all files"

# 3. Open dashboard
open http://localhost:5173

# 4. You should see events with your project name
```

## 🚀 Quick Start (Try It in This Repo)

Test the observability system using this repo's built-in configuration:

```bash
# 1. Start the server and client
./scripts/start-system.sh

# 2. Open the dashboard
open http://localhost:5173

# 3. In Claude Code, run any command
# Example: "Run git ls-files to understand the codebase"

# 4. Watch events stream in real-time on the dashboard
```

## 📁 Project Structure

```
multi-agent-workflow/
│
├── apps/                           # Application components
│   ├── server/                     # Bun TypeScript server
│   │   ├── src/
│   │   │   ├── index.ts           # Main server with HTTP/WebSocket endpoints
│   │   │   ├── db.ts              # SQLite database management & migrations
│   │   │   └── types.ts           # TypeScript interfaces
│   │   ├── data/                  # SQLite database files (gitignored)
│   │   ├── logs/                  # Server logs (gitignored)
│   │   └── package.json
│   │
│   ├── client/                     # Vue 3 TypeScript client
│   │   ├── src/
│   │   │   ├── App.vue            # Main app with theme & WebSocket management
│   │   │   ├── components/
│   │   │   │   ├── EventTimeline.vue      # Event list with auto-scroll
│   │   │   │   ├── EventRow.vue           # Individual event display
│   │   │   │   ├── FilterPanel.vue        # Multi-select filters
│   │   │   │   ├── ChatTranscriptModal.vue # Chat history viewer
│   │   │   │   ├── StickScrollButton.vue  # Scroll control
│   │   │   │   └── LivePulseChart.vue     # Real-time activity chart
│   │   │   ├── composables/
│   │   │   │   ├── useWebSocket.ts        # WebSocket connection logic
│   │   │   │   ├── useEventColors.ts      # Color assignment system
│   │   │   │   ├── useChartData.ts        # Chart data aggregation
│   │   │   │   └── useEventEmojis.ts      # Event type emoji mapping
│   │   │   ├── utils/
│   │   │   │   └── chartRenderer.ts       # Canvas chart rendering
│   │   │   └── types.ts           # TypeScript interfaces
│   │   ├── logs/                  # Client logs (gitignored)
│   │   └── package.json
│   │
│   └── demo-cc-agent/              # Demo project with observability
│
├── .claude/                        # Claude Code configuration (source templates)
│   ├── hooks/
│   │   └── observability/         # Hook scripts (Python with uv)
│   │       ├── send_event.py      # Universal event sender
│   │       ├── pre_tool_use.py    # Tool validation & blocking
│   │       ├── post_tool_use.py   # Result logging
│   │       ├── notification.py    # User interaction events
│   │       ├── user_prompt_submit.py # User prompt logging & validation
│   │       ├── stop.py            # Session completion
│   │       ├── subagent_stop.py   # Subagent completion
│   │       ├── pre_compact.py     # Context compaction tracking
│   │       ├── session_start.py   # Session initialization
│   │       ├── session_end.py     # Session cleanup
│   │       ├── utils/             # Shared utilities
│   │       │   ├── constants.py   # Configuration constants
│   │       │   ├── hitl.py        # Human-in-the-loop utilities
│   │       │   ├── summarizer.py  # AI summary generation
│   │       │   ├── model_extractor.py # Model info extraction
│   │       │   ├── load-config.sh # Bash config loader
│   │       │   ├── llm/           # LLM integrations
│   │       │   │   ├── anth.py    # Anthropic API
│   │       │   │   └── ollama.py  # Ollama API
│   │       │   └── tts/           # Text-to-speech
│   │       │       ├── elevenlabs_tts.py
│   │       │       ├── openai_tts.py
│   │       │       └── pyttsx3_tts.py
│   │       └── examples/          # Hook usage examples
│   │
│   ├── agents/                    # Specialized AI agents
│   │   ├── summary-processor.md  # Jerry - On-demand summaries
│   │   ├── observability-manager.md # Kim - System management
│   │   ├── ghcli.md              # Mark - GitHub operations (legacy)
│   │   ├── fetch-docs-haiku45.md # Haiku doc fetcher
│   │   └── fetch-docs-sonnet45.md # Sonnet doc fetcher
│   │
│   ├── commands/                  # Custom slash commands
│   │   ├── process-summaries.md  # On-demand summary generation
│   │   ├── bun-start.md          # Start system convenience command
│   │   ├── bun-stop.md           # Stop system convenience command
│   │   ├── convert_paths_absolute.md # Path conversion utility
│   │   └── bench/                # Benchmarking commands
│   │
│   ├── status_lines/             # Status line scripts
│   │   └── git-status.sh        # Git branch/status display
│   │
│   ├── data/                     # Session data storage
│   │   └── sessions/            # Session transcripts (gitignored)
│   │
│   ├── settings.json            # Hook configuration template
│   ├── .observability-state     # Runtime state (enabled/disabled)
│   └── .observability-config    # Environment-specific config (gitignored)
│
├── scripts/                      # Management scripts
│   ├── start-system.sh          # Launch server & client
│   ├── stop-system.sh           # Stop all processes
│   ├── test-system.sh           # System validation
│   ├── observability-setup.sh   # Install to other projects
│   ├── observability-enable.sh  # Enable event streaming
│   ├── observability-disable.sh # Disable event streaming
│   ├── observability-status.sh  # Check system status
│   ├── observability-load-config.sh # Load config helper
│   └── git-ai.sh                # Git with AI attribution
│
├── ai_docs/                     # AI-fetched documentation
│   ├── haiku45/                 # Haiku 4.5 benchmarks
│   └── sonnet45/                # Sonnet 4.5 benchmarks
│
├── app_docs/                    # Project documentation
│   └── *.md                     # Design docs, specs, guides
│
├── specs/                       # Technical specifications
│   └── *.md                     # Feature specs, architecture docs
│
├── logs/                        # Application logs (gitignored)
│   └── [session-id]/           # Per-session log directories
│
└── images/                      # README assets
    ├── app.png
    └── AgentDataFlowV2.gif
```

## 🔧 Component Details

### 1. Hook System (`.claude/hooks/`)

> If you want to master claude code hooks watch [this video](https://github.com/disler/claude-code-hooks-mastery)

The hook system intercepts Claude Code lifecycle events:

- **`send_event.py`**: Core script that sends event data to the observability server
  - Supports `--add-chat` flag for including conversation history
  - Validates server connectivity before sending
  - Handles all event types with proper error handling

- **Event-specific hooks**: Each implements validation and data extraction
  - `pre_tool_use.py`: Blocks dangerous commands, validates tool usage
  - `post_tool_use.py`: Captures execution results and outputs
  - `notification.py`: Tracks user interaction points
  - `user_prompt_submit.py`: Logs user prompts, supports validation (v1.0.54+)
  - `stop.py`: Records session completion with optional chat history
  - `subagent_stop.py`: Monitors subagent task completion
  - `pre_compact.py`: Tracks context compaction operations (manual/auto)
  - `session_start.py`: Logs session start, can load development context
  - `session_end.py`: Logs session end, saves session statistics

### 2. Server (`apps/server/`)

Bun-powered TypeScript server with real-time capabilities:

- **Database**: SQLite with WAL mode for concurrent access
- **Endpoints**:
  - `POST /events` - Receive events from agents
  - `GET /events/recent` - Paginated event retrieval with filtering
  - `GET /events/filter-options` - Available filter values
  - `WS /stream` - Real-time event broadcasting
- **Features**:
  - Automatic schema migrations
  - Event validation
  - WebSocket broadcast to all clients
  - Chat transcript storage

### 3. Client (`apps/client/`)

Vue 3 application with real-time visualization:

- **Visual Design**:
  - Dual-color system: App colors (left border) + Session colors (second border)
  - Gradient indicators for visual distinction
  - Dark/light theme support
  - Responsive layout with smooth animations

- **Features**:
  - Real-time WebSocket updates
  - Multi-criteria filtering (app, session, event type)
  - Live pulse chart with session-colored bars and event type indicators
  - Time range selection (1m, 3m, 5m) with appropriate data aggregation
  - Chat transcript viewer with syntax highlighting
  - Auto-scroll with manual override
  - Event limiting (configurable via `VITE_MAX_EVENTS_TO_DISPLAY`)

- **Live Pulse Chart**:
  - Canvas-based real-time visualization
  - Session-specific colors for each bar
  - Event type emojis displayed on bars
  - Smooth animations and glow effects
  - Responsive to filter changes

### 4. AI Summary System

The system offers two modes for generating AI summaries of hook events:

#### **Real-time Summaries**
- Automatically generates concise summaries as events occur
- Uses Anthropic API via Python hooks
- Requires `ANTHROPIC_API_KEY` in `.env` file
- Enable in Settings tab by switching to "Real-time" mode
- Summaries appear immediately when events are captured
- Best for continuous monitoring and instant insights

**💰 Cost Warning:** Real-time summaries cost ~few cents per 10 summaries and add up quickly during active development. Only enable when actively monitoring the dashboard.

#### **On-Demand Summaries** (Recommended for Cost Savings)
- Manual summary generation via GUI button
- Uses Jerry subagent (Haiku 4.5) for batch processing
- No API key required (uses your Claude Code session)
- Workflow:
  1. Click "Generate Summaries" button in FilterPanel
  2. Run `/process-summaries` command in Claude Code
  3. Jerry reads events from `.summary-prompt.txt`
  4. Summaries are batch-generated and updated in database
- Best for occasional reviews or when you don't need real-time summaries

**Summary Format**:
- One sentence only (no period at end)
- Focus on key action or information
- Specific and technical
- Under 15 words
- Present tense

**Meta-Events**:
Events related to summary processing itself (Jerry's operations) are automatically tagged with `[Meta-event:` prefix and styled with orange background for easy identification.

### 5. Git Helper with AI Attribution

The `scripts/git-ai.sh` helper provides automated git operations with full AI attribution and provenance tracking:

**Features**:
- Automatic AI attribution in commit messages
- Provenance metadata tracking
- SSH key management via keychain
- Prevents SSH askpass errors
- Required for all git operations that use SSH

**Usage**:
```bash
# Instead of: git commit -m "message"
./scripts/git-ai.sh commit -m "message"

# Instead of: git push
./scripts/git-ai.sh push

# Other supported commands
./scripts/git-ai.sh pull
./scripts/git-ai.sh fetch
./scripts/git-ai.sh clone <url>
```

**CRITICAL**: Always use `./scripts/git-ai.sh` for git commands requiring SSH (commit, push, pull, fetch, clone, remote, ls-remote, submodule). This ensures proper SSH authentication and adds AI attribution metadata.

### 6. Automated GitHub Operations (Mark Agent)

The Mark agent (`subagent_type=mark`) handles ALL GitHub CLI operations with full provenance tracking:

**Capabilities**:
- Create pull requests with AI attribution
- Add comments to PRs and issues
- Manage issue labels and assignments
- Full provenance tracking via `.github/workflows/gh-dispatch-ai.yml`

**Provenance Tracking**:
All GitHub operations are tracked with:
- `Provenance`: Always `Claude_AI`
- `Session ID`: Unique identifier for the agent session
- `Timestamp`: When the operation was requested
- `Context`: Full context about what was being worked on

**Example Workflow**:
```yaml
# Dispatched by Mark agent
name: gh-dispatch-ai
on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform (pr-create, pr-comment, issue-comment)'
        required: true
      provenance:
        description: 'Who/what initiated this (always Claude_AI)'
        required: true
```

**IMPORTANT**: Never call `gh` CLI commands directly - always use the Mark agent via the Task tool to ensure proper provenance tracking.

## 🤖 Specialized Agents

The system includes purpose-built AI agents for specific workflow tasks:

### Jerry (Summary Processor)
**Purpose**: Generates concise AI summaries for hook events on-demand
**Model**: Claude Haiku 4.5 (fast, cost-effective)
**Tools**: Bash (for database updates)
**Color**: Orange

**Workflow**:
1. User clicks "Generate Summaries" button in GUI
2. System saves prompt to `.summary-prompt.txt` with all events needing summaries
3. User runs `/process-summaries` command
4. Jerry reads the file and generates summaries following strict format rules
5. Jerry updates database via batch API call
6. GUI reflects updated summaries in real-time

**Summary Rules**:
- ONE sentence only (no period at end)
- Focus on key action or information
- Specific and technical
- Under 15 words
- Present tense
- No quotes or extra formatting

**Auto-Dispatch**: When user says "Process summaries from .summary-prompt.txt", Jerry is automatically dispatched.

### Mark (GitHub Operations Manager)
**Purpose**: Handles ALL GitHub CLI operations with full provenance tracking
**Model**: Configurable (uses your main Claude Code session)
**Tools**: Bash (git commands only), Read (context gathering)
**Restrictions**: No file writes, no SSH, no direct `gh pr/issue` commands

**Workflow**:
1. Mark gathers context from current working directory
2. Mark dispatches `.github/workflows/gh-dispatch-ai.yml` workflow
3. Workflow runs with provenance metadata (always `Claude_AI`)
4. GitHub operation executes (create PR, add comment, etc.)
5. Results are logged with full attribution

**Operations Supported**:
- `pr-create`: Create pull requests
- `pr-comment`: Add comments to PRs
- `issue-comment`: Add comments to issues

**Why Use Mark?**:
- Ensures proper provenance tracking (who/what initiated the action)
- Prevents SSH authentication errors
- Centralizes GitHub operations in auditable workflow
- Adds AI attribution to all GitHub interactions

**CRITICAL**: Mark is SOLELY responsible for ALL `gh` CLI calls. NO EXCEPTIONS.

## 🔄 Data Flow

1. **Event Generation**: Claude Code executes an action (tool use, notification, etc.)
2. **Hook Activation**: Corresponding hook script runs based on `settings.json` configuration
3. **Data Collection**: Hook script gathers context (tool name, inputs, outputs, session ID)
4. **Transmission**: `send_event.py` sends JSON payload to server via HTTP POST
5. **Server Processing**:
   - Validates event structure
   - Stores in SQLite with timestamp
   - Broadcasts to WebSocket clients
6. **Client Update**: Vue app receives event and updates timeline in real-time

## 🎨 Event Types & Visualization

| Event Type       | Emoji | Purpose                | Color Coding  | Special Display                       |
| ---------------- | ----- | ---------------------- | ------------- | ------------------------------------- |
| PreToolUse       | 🔧     | Before tool execution  | Session-based | Tool name & details                   |
| PostToolUse      | ✅     | After tool completion  | Session-based | Tool name & results                   |
| Notification     | 🔔     | User interactions      | Session-based | Notification message                  |
| Stop             | 🛑     | Response completion    | Session-based | Summary & chat transcript             |
| SubagentStop     | 👥     | Subagent finished      | Session-based | Subagent details                      |
| PreCompact       | 📦     | Context compaction     | Session-based | Compaction details                    |
| UserPromptSubmit | 💬     | User prompt submission | Session-based | Prompt: _"user message"_ (italic)     |
| SessionStart     | 🚀     | Session started        | Session-based | Session source (startup/resume/clear) |
| SessionEnd       | 🏁     | Session ended          | Session-based | End reason (clear/logout/exit/other)  |

### UserPromptSubmit Event (v1.0.54+)

The `UserPromptSubmit` hook captures every user prompt before Claude processes it. In the UI:
- Displays as `Prompt: "user's message"` in italic text
- Shows the actual prompt content inline (truncated to 100 chars)
- Summary appears on the right side when AI summarization is enabled
- Useful for tracking user intentions and conversation flow


## 🧪 Testing

```bash
# System validation
./scripts/test-system.sh

# Manual event test
curl -X POST http://localhost:4000/events \
  -H "Content-Type: application/json" \
  -d '{
    "source_app": "test",
    "session_id": "test-123",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "Bash", "tool_input": {"command": "ls"}}
  }'
```

## ⚙️ Configuration

### Environment Variables

The project uses a single `.env` file for configuration:

**`.env`** - Place in **two locations**:
1. **Project root** (`.env`) - For Python hooks
2. **Server directory** (`apps/server/.env`) - For Bun server

**Environment Variables**:
- `ANTHROPIC_API_KEY` – Anthropic Claude API key (required for real-time summaries)
- `ENGINEER_NAME` – Your name (optional, used in TTS notifications)
- `OPENAI_API_KEY` – OpenAI API key (optional, for TTS and completion messages)
- `ELEVENLABS_API_KEY` – ElevenLabs API key (optional, for TTS notifications)
- `ELEVENLABS_VOICE_ID` – ElevenLabs voice ID (optional, defaults to Adam voice)
- `GEMINI_API_KEY` – Google Gemini API key (optional)

**Setup**:
```bash
# Copy example file to both locations
cp .env.sample .env
cp .env apps/server/.env

# Edit and add your API keys
nano .env
```

**Client** (`.env` file in `apps/client/.env`):
- `VITE_MAX_EVENTS_TO_DISPLAY=100` – Maximum events to show (removes oldest when exceeded)

### Server Ports

- Server: `4000` (HTTP/WebSocket)
- Client: `5173` (Vite dev server)

## 🛡️ Security Features

- Blocks dangerous commands (`rm -rf`, etc.)
- Prevents access to sensitive files (`.env`, private keys)
- Validates all inputs before execution
- No external dependencies for core functionality

## 📊 Technical Stack

- **Server**: Bun, TypeScript, SQLite
- **Client**: Vue 3, TypeScript, Vite, Tailwind CSS
- **Hooks**: Python 3.8+, Astral uv, TTS (ElevenLabs or OpenAI), LLMs (Claude or OpenAI)
- **Communication**: HTTP REST, WebSocket

## 🔧 Troubleshooting

### Hook Scripts Not Working

If your hook scripts aren't executing properly, it might be due to relative paths in your `.claude/settings.json`. Claude Code documentation recommends using absolute paths for command scripts.

**Solution**: Use the custom Claude Code slash command to automatically convert all relative paths to absolute paths:

```bash
# In Claude Code, simply run:
/convert_paths_absolute
```

This command will:
- Find all relative paths in your hook command scripts
- Convert them to absolute paths based on your current working directory
- Create a backup of your original settings.json
- Show you exactly what changes were made

This ensures your hooks work correctly regardless of where Claude Code is executed from.

## Master AI **Agentic Coding**
> And prepare for the future of software engineering

Learn tactical agentic coding patterns with [Tactical Agentic Coding](https://agenticengineer.com/tactical-agentic-coding?y=cchobvwh45)

Follow the [IndyDevDan YouTube channel](https://www.youtube.com/@indydevdan) to improve your agentic coding advantage.

