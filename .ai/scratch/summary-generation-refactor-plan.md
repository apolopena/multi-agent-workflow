# Summary Generation Refactor - Current State & Plan

## Context
User discovered the "Save To" dropdown for summary generation is problematic:
- Security risk: allowing user to specify arbitrary file paths
- Over-engineered: project registration system is complex
- Multi-project support not needed: this repo is the only one with server/client

## Current State (What We Built Today)

### What Works
1. **Collapsible summary panel** - Clean UI, summary controls hidden until needed ✅
2. **Persistent project storage** - Projects stored in SQLite, survive restarts ✅
3. **Fixed .env loading** - Server runs from project root, picks up ANTHROPIC_API_KEY ✅
4. **Project registration** - Hook calls `/projects/register` on session start ✅
5. **WebSocket broadcasting** - Projects broadcast via WebSocket (proper Vue pattern) ✅

### The Problem
- "Save To" dropdown shows registered projects
- Accepting `destination_path` from client is a security risk (path traversal)
- We don't need multi-project support - just write to this repo

## The Solution (What to Implement)

### Remove Multi-Project Support
1. **Remove "Save To" dropdown** from FilterPanel.vue
2. **Hardcode destination** - always write to repo root: `/home/quadro/repos/work/multi-agent-workflow/.summary-prompt.txt`
3. **Update server endpoint** - `/events/save-summary-prompt` doesn't accept `destination_path`
4. **Show success message** - tell user where file was written

### Files to Change

#### 1. FilterPanel.vue (apps/client/src/components/FilterPanel.vue)
- Remove "Save To" dropdown section (lines 87-100)
- Remove `selectedDestination` ref
- Remove `projects` prop from props definition
- Update `generateSummaries()` to not send `destination_path`

#### 2. index.ts (apps/server/src/index.ts)
- Update `/events/save-summary-prompt` endpoint (around line 307-344)
- Remove `destination_path` from request body
- Hardcode path: `const filePath = '/home/quadro/repos/work/multi-agent-workflow/.summary-prompt.txt';`
- Still validate prompt exists

#### 3. App.vue (apps/client/src/App.vue)
- Remove `projects` from useWebSocket destructure (line 154)
- Remove `:projects="projects"` prop from FilterPanel (line 72)

#### 4. Optional Cleanup (Can Do Later)
- Remove project registration from session_start.py (or leave it harmless)
- Remove projects table from database (or ignore it)
- Remove project WebSocket handling (or leave it)

### Result
- Simple, secure, single-repo summary generation
- User clicks "Generate Summaries" → writes to repo root → shows path
- No dropdowns, no project selection, no security risk

## Testing Steps
1. Remove changes above
2. Restart server (for server-side changes)
3. Refresh client
4. Click "Generate Summaries"
5. Should write to `/home/quadro/repos/work/multi-agent-workflow/.summary-prompt.txt`
6. Run `/process-summaries` from repo root
7. Summaries should work

## Notes
- Keep the collapsible panel UI (that's good)
- Keep WebSocket updates for summaries (that works)
- Just remove the project selection complexity
