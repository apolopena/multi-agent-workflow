# Planning System

## Overview
Context Engineering system using PRPs (Product Requirements Prompts) for one-pass implementation success.

## Structure
```
.ai/planning/
├── templates/               # All templates (tracked)
│   ├── PLANNING_TEMPLATE.md # Work Table template
│   └── TASKS_TEMPLATE.md    # Task ledger template
├── prp/
│   ├── templates/           # PRP generation templates (tracked)
│   │   ├── prp_bulk.md      # Initial build (comprehensive context)
│   │   ├── prp_standalone.md # Post-MVP (lean context)
│   │   └── proposal_standalone.md # Seed spec format
│   ├── instances/           # Generated PRPs (untracked)
│   ├── proposals/           # Seed specs for standalone work (untracked)
│   └── archive/             # Historical PRPs (untracked)
└── README.md                # This file (tracked)

.ai/planning/prd/PLANNING.md  # Active Work Table (tracked)

.ai/scratch/TASKS.md         # Work ledger (untracked, copy of template)
```

## Workflow

### Phase 1: Initial Build (Mode 1)
1. Create `.ai/planning/prd/PLANNING.md` with WP-1 to WP-N rows
2. Run `/generate-prp .ai/planning/prd/PLANNING.md`
3. Generates bulk PRPs for all Work Table rows
4. Initial rows become **FROZEN** (never edit after this)

### Phase 2: Post-MVP Features (Mode 2)
1. Create proposal: `.ai/planning/prp/proposals/WP-10_feature.md`
2. Run `/generate-prp .ai/planning/prp/proposals/WP-10_feature.md`
3. Auto-adds row to Work Table below frozen section
4. Generates lean PRP: `.ai/planning/prp/instances/WP-10_feature.md`

### Phase 3: Execution
1. Run `/execute-prp .ai/planning/prp/instances/WP-10_feature.md`
2. Implement feature following PRP
3. Run validation gates
4. Update `.ai/scratch/TASKS.md` on completion

## Work Table Rules
- **WP-1 to WP-N**: Initial build rows, FROZEN after Mode 1
- **WP-10+**: Post-MVP rows, auto-added by Mode 2
- **Never modify or delete** frozen rows
- Each proposal auto-adds one new row

## Multi-Engineer ID Blocks
- Engineer A: WP-10 to WP-19
- Engineer B: WP-20 to WP-29
- Engineer C: WP-30 to WP-39

Check existing proposals and Work Table for next available ID in your block.

## Key Commands
- `/generate-prp <planning-or-proposal-file>` - Generate PRPs
- `/execute-prp <prp-instance-file>` - Implement feature

## Idempotency
- Mode 1 skips rows with existing PRPs or execution results
- Mode 2 skips adding row if ID already exists in Work Table
- Safe to re-run commands
