# PRP System

**PRP** = Probably Requirements & Pseudocode

Structured workflow for managing project implementation from initial build through post-MVP incremental development.

## Directory Structure

```
.ai/prp/
├── templates/          # Meta-templates (customize for your project)
│   ├── prp_bulk.md              # Comprehensive template (initial build)
│   ├── prp_standalone.md        # Lightweight template (post-MVP)
│   └── proposal_standalone.md   # Starter for writing proposals manually
├── proposals/          # Manual input specs (10-30 lines, gitignored)
└── instances/          # AI-generated PRPs (gitignored)
```

## What Goes Where

**templates/** - Project-customized templates
- Copy these and replace `[PROJECT_LINT_COMMAND]` and `[PROJECT_TEST_COMMAND]` with your actual commands
- Commit customized templates to your repo
- These are meta-templates: templates to create templates

**proposals/** - Manual input (ephemeral, not tracked)
- You create these: 10-30 line specs with ID, What, Why, How
- System reads them to generate full PRPs
- Gitignored because they're just input scaffolding

**instances/** - AI-generated output (ephemeral, not tracked)
- System generates complete PRPs here
- You execute these: `/execute-prp .ai/prp/instances/WP-X-Y_feature.md`
- Gitignored because they're just intermediate artifacts
- Permanent record is in Work Table + commits

## Two Workflows

### Initial Build (Bulk Mode)

Generate comprehensive PRPs from PLANNING.md Work Table:

```bash
# 1. Create PLANNING.md with Work Table
/convert-to-planning .ai/scratch/my-spec.md

# 2. Generate all PRPs
/generate-prp .ai/prd/PLANNING.md

# 3. Execute in order (see Execution Order in PLANNING.md)
/execute-prp .ai/prp/instances/WP-A-1_backend-core.md
```

### Post-MVP (Standalone Mode)

Generate focused PRPs from lightweight proposals:

```bash
# 1. Create proposal manually
# File: .ai/prp/proposals/WP-D-2_contact-form.md
# Content: ID, What, Why, How (10-30 lines)

# 2. Generate PRP
/generate-prp .ai/prp/proposals/WP-D-2_contact-form.md
# → Auto-adds row to Work Table
# → Generates standalone PRP

# 3. Execute PRP
/execute-prp .ai/prp/instances/WP-D-2_contact-form.md
```

## Key Concepts

**Bulk PRPs** - Comprehensive PRPs for initial build
- Generated from PLANNING.md Work Table
- Uses `prp_bulk.md` template
- Full context, extensive validation

**Standalone PRPs** - Lightweight PRPs for post-MVP work
- Generated from proposals
- Uses `prp_standalone.md` template
- Focused, minimal context

**Proposals** - Manual input specs
- You create these (10-30 lines)
- Format: ID, What, Why, How
- System expands to full PRP
- Ephemeral (gitignored)

**Instances** - Generated PRPs ready to execute
- AI creates these from proposals or PLANNING.md
- Complete implementation guides
- Ephemeral (gitignored)

**Validation Loop** - Mandatory in every PRP
- Level 1: Lint/syntax checks
- Level 2: Unit tests
- Must iterate until both pass
- No integration tests (those happen later)

## Customizing Templates

1. Copy templates to your project (if starting fresh)
2. Replace placeholders:
   - `[PROJECT_LINT_COMMAND]` → e.g., `npm run lint`, `ruff check --fix`
   - `[PROJECT_TEST_COMMAND]` → e.g., `npm test`, `pytest tests/`
3. Remove generic language examples if desired
4. Commit customized templates

## Why Gitignore Proposals & Instances?

- They're ephemeral artifacts, not permanent records
- Work Table + changelog are the source of truth
- Avoids merge conflicts on shared directories
- Keeps git history clean
- Can regenerate anytime from Work Table

## Parallel Work Strategy

Work Table uses grouped IDs: `WP-{GROUP}-{NUMBER}`
- Same letter = same work area (sequential)
- Different letters = parallel work areas

Example:
```
Execution Order:
1. Group A (sequential): WP-A-1, then WP-A-2
2. Groups B, C, D (parallel): After WP-A-1, all three run simultaneously
3. Group E (parallel): After WP-A-2, all run simultaneously
```

No merge conflicts because each group owns different directories.

## Commands

- `/convert-to-planning <spec-file>` - Convert plan to PLANNING.md format
- `/generate-prp PLANNING.md` - Generate bulk PRPs
- `/generate-prp .ai/prp/proposals/WP-X-Y_feature.md` - Generate standalone PRP
- `/execute-prp .ai/prp/instances/WP-X-Y_feature.md` - Execute PRP

See `.ai/context_engineering.md` for complete visual workflow.
