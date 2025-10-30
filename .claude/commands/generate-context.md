---
description: Generate/update .ai/scratch/context-primer.md with current working state
---

**Generate new context**

## Step 1: Read Available Documentation
Read `.ai/docs/README.md` to understand what documentation is available for context.

## Step 2: Run Git Commands
- `git branch --show-current`
- `git log -5 --oneline` (5 commits max)
- `git status --short` (counts only, don't list every file)
- `git diff --cached --stat` (stat line only, don't analyze content)

## Step 3: Read Recent CHANGELOG
Read from `CHANGELOG.md` - whichever provides MORE context:
- Last 3 version sections, OR
- Last 100 commit entries
Choose whichever gives more comprehensive information about recent progress.

## Step 4: Generate Context File

```markdown
# Branch Context: <branch-name>

## Goal
<1 sentence from branch name>

## Recent Changes (from CHANGELOG)
- <Summary from last 3 version sections OR last 100 commit entries, whichever is more comprehensive>

## Progress
- [x] <Completed items from commits>
- [ ] <In-progress from staged files>

## Next Steps
- <Next items to work on>

## Notes
<Blockers or critical info only>
```

Analyze git state, CHANGELOG, and available docs, then create/update `.ai/scratch/context-primer.md`.

## Rules

- File path: `.ai/scratch/context-primer.md`
- Always overwrite file
- **Target ~300 lines (hard max 400)** - comprehensive but focused
- Use checkboxes: [x] done, [ ] pending
