# Branch Context: feat/context-engineering-system

## Goal
Refactor planning system to match agent-cece structure with centralized `.ai/planning/` directory and improved TTS support.

## Recent Changes (from CHANGELOG)

### Unreleased - Context Engineering System
**Branch:** `feat/context-engineering-system` → `main` · **Status:** Open

- **Context Engineering Framework** [e94f21f]
  - Added comprehensive Context Engineering workflow system documented in `.ai/context_engineering.md`
  - Implemented Product Requirements Planning (PRP) framework with bulk and standalone templates
  - Added `prp_bulk.md`, `prp_standalone.md`, and `proposal_standalone.md` templates with README
  - Created comprehensive planning framework with `PLANNING.md`, `PLANNING_MIGRATE.md`, and supporting docs
  - Added Context Engineering support tools and scratch documentation for architecture, deployment, email, WebSocket
  - Added `convert-to-planning` command for planning format conversion

- **Recent Infrastructure Updates** [449fe31, 93512a7]
  - Expanded CHANGELOG with multiple changes per commit
  - Updated CHANGELOG for Context Engineering system

### v1.0.5 - Setup Enhancements
**PR #8** · `feat/infrastructure-updates` → `main` · **Status:** Merged

- **Setup Script Enhancement** [8f0f790]
  - Added comprehensive overwrite warnings listing all affected files
  - Categorized summary of changes during setup

### v1.0.4 - UX and Agent Improvements
**PR #7** · `feat/infrastructure-updates` → `main` · **Status:** Merged

- **Summary UX** [22006ad]
  - Simplified summary generation with one-button operation hardcoded to repo root
  - Fixed `.env` loading by running server from project root instead of `apps/server`

- **New Agents** [22006ad]
  - Atlas agent: Generates `context.md` and `architecture.md` documentation
  - Bixby agent: HTML formatting operations

- **Database & Project Management** [22006ad]
  - Implemented project registration with database persistence

- **Documentation Reorganization** [22006ad]
  - Moved `ai_docs` to `.ai/docs`
  - Removed `demo-cc-agent` directory and obsolete test/benchmark files

- **CHANGELOG Fixes** [22006ad]
  - Fixed version ordering to use proper semantic version sort

- **Configuration Cleanup** [22006ad]
  - Removed deprecated agents and commands from `.claude` config
  - Updated `generate-context` command with improved functionality

### v1.0.3 - Changelog Management
**PR #6** · `feat/infrastructure-updates` → `main` · **Status:** Merged

- **Pedro Agent** [1e69a37]
  - Added changelog manager with automated verification to prevent duplicate entries

## Progress

### Completed
- [x] Created centralized `.ai/planning/` directory structure
- [x] Moved planning templates to `.ai/planning/templates/`
- [x] Moved PRP system to `.ai/planning/prp/` with subdirectories
- [x] Created `.ai/planning/README.md` with comprehensive workflow documentation
- [x] Created `.ai/AGENTS.md` with planning system directives for agents
- [x] Updated `.ai/context_engineering.md` to redirect to new locations
- [x] Renamed `convert-to-planning` command to `convert-planning`
- [x] Added new commands: `/generate-prp` and `/execute-prp`
- [x] Updated CHANGELOG with Context Engineering system entries
- [x] Expanded CHANGELOG format to show multiple changes per commit
- [x] Removed `.ai/scratch` files from tracking
- [x] Ported TTS fixes from agent-cece (OpenAI TTS with mpv fallback)
- [x] Created cleanup scripts for old planning directories

### Current State (Working Files)
- Modified: `.ai/context_engineering.md` - Redirects to new structure
- Modified: `.claude/commands/convert-planning.md` - Renamed from convert-to-planning
- Modified: `.claude/hooks/observability/utils/tts/openai_tts.py` - TTS fixes ported
- Modified: `.gitignore` - Added planning system untracked paths
- Modified: `CLAUDE.md` - Updated with planning directives
- Modified: `README.md` - Updated with planning system references
- Deleted: Old `.ai/prd/` files (moved to `.ai/planning/prd/`)
- Deleted: Old `.ai/prp/` files (moved to `.ai/planning/prp/`)
- New: `.ai/AGENTS.md` - Planning directives for agents
- New: `.ai/planning/` - Complete directory structure with templates
- New: `.claude/commands/generate-prp.md` - PRP generation command
- New: `.claude/commands/execute-prp.md` - PRP execution command
- New: `scripts/cleanup-old-planning-dirs.sh` - Cleanup utility
- New: `scripts/untrack-scratch.sh` - Git untracking utility

### Staged Files
- None currently staged

## Directory Structure Changes

### Old Structure (Removed)
```
.ai/
├── prd/
│   ├── PLANNING.md
│   └── PLANNING_MIGRATE.md
└── prp/
    ├── README.md
    └── templates/
        ├── proposal_standalone.md
        ├── prp_bulk.md
        └── prp_standalone.md
```

### New Structure (Current)
```
.ai/
├── AGENTS.md                    # Planning directives for agents
├── planning/
│   ├── README.md                # Complete workflow documentation
│   ├── templates/               # All templates (tracked)
│   │   ├── PLANNING_TEMPLATE.md
│   │   └── TASKS_TEMPLATE.md
│   ├── prd/                     # Product Requirements
│   │   ├── PLANNING.md          # Active Work Table (tracked)
│   │   └── PLANNING_MIGRATE.md
│   └── prp/                     # Product Requirements Prompts
│       ├── README.md
│       ├── templates/           # PRP generation templates (tracked)
│       │   ├── prp_bulk.md
│       │   ├── prp_standalone.md
│       │   └── proposal_standalone.md
│       ├── instances/           # Generated PRPs (untracked)
│       ├── proposals/           # Seed specs (untracked)
│       └── archive/             # Historical PRPs (untracked)
└── scratch/
    └── TASKS.md                 # Work ledger (untracked)
```

## Planning System Workflow

### Two-Mode System

**Mode 1: Initial Build (Bulk)**
1. Create `.ai/planning/prd/PLANNING.md` with WP-1 to WP-N rows
2. Run `/generate-prp .ai/planning/prd/PLANNING.md`
3. Generates comprehensive PRPs with full context for all rows
4. Initial rows become **FROZEN** (never edit after this)

**Mode 2: Post-MVP Features (Standalone)**
1. Create proposal: `.ai/planning/prp/proposals/WP-10_feature.md`
2. Run `/generate-prp .ai/planning/prp/proposals/WP-10_feature.md`
3. Auto-adds row to Work Table below frozen section
4. Generates lean PRP: `.ai/planning/prp/instances/WP-10_feature.md`

**Mode 3: Execution**
1. Run `/execute-prp .ai/planning/prp/instances/WP-10_feature.md`
2. Implement feature following PRP
3. Run validation gates
4. Update `.ai/scratch/TASKS.md` on completion

### Work Table Rules
- **WP-1 to WP-N**: Initial build rows, FROZEN after Mode 1 completes
- **WP-10+**: Post-MVP rows, auto-added by Mode 2
- **Never modify or delete** frozen rows
- Each proposal auto-adds one new row to growing section

### Multi-Engineer ID Blocks
- Engineer A: WP-10 to WP-19
- Engineer B: WP-20 to WP-29
- Engineer C: WP-30 to WP-39

## TTS Improvements

### Ported from agent-cece
- Fixed OpenAI TTS implementation in `.claude/hooks/observability/utils/tts/openai_tts.py`
- Added proper mpv audio playback fallback
- Improved error handling and audio streaming
- Consistent with agent-cece's working implementation

## Key Commands

### Planning System
- `/convert-planning` - Convert unstructured plans to PLANNING.md format
- `/generate-prp <file>` - Generate PRPs from PLANNING.md or proposal file
- `/execute-prp <file>` - Implement feature from PRP instance file

### Context Generation (Atlas)
- `/generate-context` - Generate `.ai/scratch/context-primer.md`
- `/generate-arch` - Generate `.ai/scratch/arch-primer.md`
- `/prime-quick` - Quick prime from existing context files
- `/prime-full` - Full prime with subagent-generated context

### Observability (Kim)
- `/o-enable` - Enable observability event streaming
- `/o-disable` - Disable observability event streaming
- `/o-start` - Start observability system (server + dashboard)
- `/o-stop` - Stop observability system
- `/o-status` - Check observability system status

## Next Steps

### Pre-Merge Testing
- [ ] Test `/generate-prp` with PLANNING.md file (Mode 1)
- [ ] Test `/generate-prp` with proposal file (Mode 2)
- [ ] Test `/execute-prp` with generated PRP instance
- [ ] Verify TTS improvements work correctly
- [ ] Verify cleanup scripts work correctly
- [ ] Test end-to-end workflow with sample feature

### Documentation
- [ ] Update main README.md with planning system overview
- [ ] Verify all CLAUDE.md references point to correct locations
- [ ] Ensure all command descriptions are accurate

### Git Cleanup
- [ ] Verify old planning files are properly deleted from tracking
- [ ] Verify new untracked directories are in .gitignore
- [ ] Run cleanup scripts to remove old planning artifacts

### Final Verification
- [ ] Review all modified files for consistency
- [ ] Check that Context Engineering workflow is complete
- [ ] Verify CHANGELOG entries are accurate
- [ ] Test Atlas agent with new structure

### Merge Preparation
- [ ] Create comprehensive PR description
- [ ] Include before/after directory structure
- [ ] Document breaking changes (directory structure)
- [ ] List migration steps for existing users
- [ ] Tag relevant stakeholders for review

## Notes

### Critical Information
- **Breaking Change**: Old `.ai/prd/` and `.ai/prp/` locations are deprecated
- **Migration Required**: Existing planning files must be moved to `.ai/planning/`
- **Frozen Rows**: After running Mode 1 (`/generate-prp` on PLANNING.md), initial Work Table rows become immutable
- **Untracked Directories**: `.ai/planning/prp/instances/`, `proposals/`, and `archive/` are untracked
- **Command Rename**: `convert-to-planning` → `convert-planning`

### Agent-Specific Rules (from .ai/AGENTS.md)
1. **Never read** `.ai/planning/prp/instances/` unless user references specific file
2. **Batch file edits** using one multi-edit call; never chain single-line edits
3. **Use only dependencies** present in repo config or current PRP context
4. **Never delete or overwrite** existing code without explicit user direction
5. **Ask questions** whenever requirements or context feel ambiguous
6. **Run validation commands** specified in PRPs before declaring work complete
7. **Update TASKS.md** as soon as work finishes
8. **Record discoveries** under "Discovered During Work"
9. **Summarize changes** and surface follow-up questions before task completion

### Testing Strategy
- Use agent-cece as reference for TTS implementation validation
- Create sample PLANNING.md with 2-3 rows for Mode 1 testing
- Create sample proposal for Mode 2 testing
- Verify idempotency: safe to re-run both modes

### Documentation References
- Full workflow: `.ai/planning/README.md`
- Agent directives: `.ai/AGENTS.md`
- Context Engineering redirect: `.ai/context_engineering.md`
- Available AI docs: `.ai/docs/README.md`

### Technical Details
- **Git Branch**: feat/context-engineering-system
- **Target Branch**: main
- **Modified Files**: 21 total (5 modified, 7 deleted, 1 renamed, 8 new)
- **Last 5 Commits**:
  - 449fe31: Expand CHANGELOG with multiple changes per commit
  - 93512a7: Update CHANGELOG for Context Engineering system
  - e94f21f: Add Context Engineering system and templates
  - ebc5601: Enhance setup script with comprehensive overwrite warnings (#8)
  - 1e60a01: Remove .ai/scratch files from tracking
