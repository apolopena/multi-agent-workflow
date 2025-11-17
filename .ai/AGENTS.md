# Planning System Directives

## File Locations
- **Planning template**: `.ai/planning/templates/PLANNING_TEMPLATE.md`
- **Tasks template**: `.ai/planning/templates/TASKS_TEMPLATE.md`
- **Active planning**: `.ai/planning/prd/PLANNING.md` (tracked)
- **Work ledger**: `.ai/scratch/TASKS.md` (untracked)
- **PRP templates**: `.ai/planning/prp/templates/` (tracked)
- **Generated PRPs**: `.ai/planning/prp/instances/` (untracked)
- **Proposal seeds**: `.ai/planning/prp/proposals/` (untracked)
- **Archived PRPs**: `.ai/planning/prp/archive/` (untracked)

## Context Engineering Workflow
1. Use `/generate-prp` with PLANNING.md or proposal file to create PRPs
2. Use `/execute-prp` with PRP instance file to implement features
3. Update `.ai/scratch/TASKS.md` when work completes
4. Never read `.ai/planning/prp/instances/` unless user references specific file

## PLANNING.md Work Table Rules
- **Initial build rows** (WP-1 to WP-N for MVP): FROZEN after `/generate-prp` Mode 1 completes
- **Never modify or delete** frozen rows
- **Post-MVP rows** (WP-10+): Growing section, auto-added by `/generate-prp` Mode 2 from proposals
- Each new proposal file auto-adds one row to the Work Table growing section

## Execution Discipline
- Batch file edits using one multi-edit call; never chain single-line edits
- Use only dependencies present in the repo configuration or current PRP context
- Do not delete or overwrite existing code without explicit user direction
- Ask questions whenever requirements or context feel ambiguous—never invent details

## Testing & Completion
- Run validation commands specified in PRPs before declaring work complete
- Update `.ai/scratch/TASKS.md` as soon as work finishes
- Record discoveries under "Discovered During Work"
- Summarize changes and surface follow-up questions before task completion
