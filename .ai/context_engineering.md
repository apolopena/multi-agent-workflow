# Context Engineering

Structured workflow for managing projects from initial build through post-MVP incremental development using PRP (Probably Requirements & Pseudocode).

## Visual Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INITIAL PROJECT BUILD (Once)                      │
└─────────────────────────────────────────────────────────────────────┘

    [Manual: create PLANNING.md]
         │
         ▼
    PLANNING.md ────────────────────┐
    ├─ Project Overview             │
    ├─ Goals/Constraints            │
    ├─ Scope/Specifications         │  These sections frozen after
    └─ Work Table:                  │  initial build (never edited)
         WP-A-1: Backend Core       │
         WP-A-2: Services Layer     │
         WP-B-1: Frontend Public    │
         WP-C-1: Frontend Admin    ─┘
         │
         │ [Manual: run command]
         ▼
    /generate-prp PLANNING.md
         │
         │ [AI reads Work Table]
         ▼
    ┌────────────────────────────┐
    │ For each row:              │
    │ - Use prp_bulk.md template │
    │ - Generate comprehensive   │
    │   PRP with full context    │
    └────────────────────────────┘
         │
         ▼
    .ai/prp/instances/
    ├─ WP-A-1_backend-core.md    ◄─── AI-generated (bulk)
    ├─ WP-A-2_services.md        ◄─── AI-generated (bulk)
    ├─ WP-B-1_frontend-public.md ◄─── AI-generated (bulk)
    └─ ...
         │
         │ [Manual: execute each PRP]
         ▼
    /execute-prp .ai/prp/instances/WP-A-1_backend-core.md
         │
         ▼
    [AI implements] ──► [Runs validation loop until passing]


┌─────────────────────────────────────────────────────────────────────┐
│                    POST-MVP INCREMENTAL WORK                         │
└─────────────────────────────────────────────────────────────────────┘

    [Manual: decide to add feature]
         │
         ▼
    [Manual: create minimal spec]
         │
         ▼
    .ai/prp/proposals/
    └─ WP-D-2_contact-form.md  ◄─── Manual input (10-30 lines)
         ## ID: WP-D-2
         ## What: Add contact form
         ## Why: Users need to reach us
         ## How: Form component + validation + API endpoint
         │
         │ [Manual: run command]
         ▼
    /generate-prp .ai/prp/proposals/WP-D-2_contact-form.md
         │
         │ [AI does 3 things:]
         ▼
    ┌─────────────────────────────────────────────┐
    │ 1. Read proposal (WP-D-2)                   │
    │ 2. Auto-add row to PLANNING.md Work Table   │
    │    WP-D-2: Contact form                     │
    │ 3. Generate standalone PRP using            │
    │    prp_standalone.md template               │
    └─────────────────────────────────────────────┘
         │
         ▼
    .ai/prp/instances/
    └─ WP-D-2_contact-form.md  ◄─── AI-generated (standalone)
         │
         │ [Manual: execute PRP]
         ▼
    /execute-prp .ai/prp/instances/WP-D-2_contact-form.md
         │
         ▼
    [AI implements] ──► [Runs validation loop until passing]


┌─────────────────────────────────────────────────────────────────────┐
│                         FILE PURPOSES                                │
└─────────────────────────────────────────────────────────────────────┘

  PLANNING.md (.ai/prd/)       ◄─── SSoT: Work Table grows, context frozen
  │
  ├─ Context (frozen) ─────────── Initial project description
  └─ Work Table (grows) ────────── All work items WP-A-1, WP-B-1, ..., WP-X-Y

  .ai/prp/templates/
  ├─ prp_bulk.md              ◄─── AI reads (comprehensive template)
  ├─ prp_standalone.md        ◄─── AI reads (lightweight template)
  └─ proposal_standalone.md   ◄─── Format guide (manual entry point)

  .ai/prp/proposals/          ◄─── Manual input (10-30 line specs)
  └─ WP-X-Y_feature.md

  .ai/prp/instances/          ◄─── AI-generated output (full PRPs)
  └─ WP-X-Y_feature.md

  .ai/scratch/                ◄─── AI-managed (ephemeral, gitignored)
  ├─ tasks.md                 ◄─── AI-maintained work log (optional)
  ├─ context-primer.md        ◄─── AI-generated session context
  └─ arch-primer.md           ◄─── AI-generated architecture
```

## File Structure

```
.ai/
├── prd/
│   └── PLANNING.md              # Project plan with frozen context + growing Work Table
├── prp/
│   ├── templates/               # Meta-templates (customize for your project)
│   │   ├── prp_bulk.md          # Comprehensive PRPs (initial build)
│   │   ├── prp_standalone.md    # Lightweight PRPs (post-MVP)
│   │   └── proposal_standalone.md  # Seed spec format (manual entry point)
│   ├── instances/               # Auto-generated PRPs (ready to execute)
│   └── proposals/               # Manual input specs (10-30 lines)
└── scratch/                     # Ephemeral AI-managed (gitignored)
```

## Two-Mode Workflow

### Mode 1: Initial Build (Bulk)
Generate comprehensive PRPs from PLANNING.md Work Table:
```bash
/generate-prp PLANNING.md
```

For each Work Table row, AI generates complete PRP using `prp_bulk.md` template with full context, validation loops, and implementation details.

### Mode 2: Post-MVP (Standalone)
Generate focused PRPs from lightweight proposals:
```bash
# 1. Create proposal manually
# .ai/prp/proposals/WP-D-2_contact-form.md (10-30 lines: ID, What, Why, How)

# 2. Generate PRP
/generate-prp .ai/prp/proposals/WP-D-2_contact-form.md
# → Auto-adds row to PLANNING.md Work Table
# → Generates standalone PRP using prp_standalone.md template

# 3. Execute PRP
/execute-prp .ai/prp/instances/WP-D-2_contact-form.md
```

## Templates

**prp_bulk.md** - Comprehensive (initial build)
- Extensive context from PLANNING.md
- Full implementation blueprint
- Validation loops with project-specific commands

**prp_standalone.md** - Lightweight (post-MVP)
- Minimal context from proposal
- Focused implementation steps
- Same validation loop structure

**proposal_standalone.md** - Seed spec (manual entry point)
- Ultra-minimal: ID, What, Why, How
- 10-30 lines
- System expands to full PRP

### Customizing Templates

1. Copy templates to your project
2. Replace placeholders:
   - `[PROJECT_LINT_COMMAND]` → your lint command (e.g., `npm run lint`, `ruff check --fix`)
   - `[PROJECT_TEST_COMMAND]` → your test command (e.g., `npm test`, `pytest tests/`)
3. Remove generic language examples if desired
4. Commit customized templates

## Validation Loops

Every PRP includes mandatory iteration until passing:

**Level 1: Syntax & Style**
```bash
[PROJECT_LINT_COMMAND]
```
Exit criteria: Zero errors, zero warnings.

**Level 2: Unit Tests**
```bash
[PROJECT_TEST_COMMAND]
```
Exit criteria: All tests pass.

**Iteration required:** If either fails, fix and re-run BOTH levels. Cannot mark work complete with failures.

**No integration tests** in PRPs - those happen later in Work Table (typically WP-G-1).

## Parallel Work Strategy

Work Table uses grouped IDs for Git worktree parallelism:

**ID Format:** `WP-{GROUP}-{NUMBER}`
- Same letter = same work area (sequential to avoid conflicts)
- Different letters = different work areas (can run in parallel)

**Example Work Table:**
```
Execution Order:
1. Group A (sequential): Complete WP-A-1, then WP-A-2
2. Groups B, C, D (parallel): After WP-A-1 completes, all three can run simultaneously
3. Group E (parallel): After WP-A-2 completes, all can run simultaneously
```

**Git Worktree Usage:**
```bash
git worktree add ../project-wp-b-1 -b feature/wp-b-1
git worktree add ../project-wp-c-1 -b feature/wp-c-1
cd ../project-wp-b-1
/execute-prp .ai/prp/instances/WP-B-1_frontend-public.md
```

No merge conflicts because each group owns different directories.

## PLANNING.md Behavior

**Context sections (frozen after initial build):**
- Project Overview, Goals, Constraints, Scope, Detailed Specifications
- Written once, never edited
- Provide full context for bulk PRP generation

**Work Table (grows continuously):**
- Initial build: WP-A-1 through WP-G-2
- Post-MVP: WP-H-1, WP-H-2, ... (from proposals)
- Auto-updated by Mode 2

**Why frozen?** Prevents polluting historical project snapshot. Proposals provide context for new features instead.

## Commands

**Convert plan to PLANNING.md:**
```bash
/convert-to-planning .ai/scratch/my-spec.md
```

**Generate PRPs (initial build):**
```bash
/generate-prp .ai/prd/PLANNING.md
```

**Generate PRP (post-MVP):**
```bash
/generate-prp .ai/prp/proposals/WP-D-2_feature.md
```

**Execute PRP:**
```bash
/execute-prp .ai/prp/instances/WP-A-1_backend-core.md
```

## Workflow Roles

**Tracked (permanent records):**
- PLANNING.md (Work Table tracks all work done/planned)
- Templates in `.ai/prp/templates/` (project-customized)
- Changelog/commits (actual implementation record)

**Not tracked (ephemeral artifacts):**
- `.ai/prp/proposals/*.md` (input scaffolding - served purpose once PRP generated)
- `.ai/prp/instances/*.md` (generated scaffolding - served purpose once work merged)
- `.ai/scratch/` (temporary working files)

**Why not track proposals/instances?**
- They're intermediate artifacts, not records of work
- Work Table + changelog are the single source of truth
- Avoids merge conflicts on shared directories
- Work Table conflicts are trivial (just renumber IDs)
- Keeps git history clean

## Quick Start

1. **Create PLANNING.md** using `/convert-to-planning` or write from scratch
2. **Customize templates** in `.ai/prp/templates/` with your project commands
3. **Generate bulk PRPs** via `/generate-prp PLANNING.md`
4. **Execute in order** following Work Table Execution Order
5. **Post-MVP**: Create proposals manually, generate standalone PRPs, execute
