# Planning System Refactor - Complete

## What Was Done

Refactored planning system to match agent-cece v0.0.2 clean structure.

### Directory Structure Changed
**Before:**
```
.ai/
├── prd/ (flat structure)
├── prp/ (flat structure)
└── context_engineering.md (296 lines, bloated)
```

**After (matches agent-cece):**
```
.ai/
├── planning/
│   ├── README.md (from agent-cece, 68 lines)
│   ├── templates/ (PLANNING + TASKS)
│   ├── prd/PLANNING.md
│   └── prp/ (templates, instances, proposals, archive)
└── context_engineering.md (19 lines, pointer)
```

### Files Updated with New Paths
1. `.claude/commands/convert-planning.md` - Save to `.ai/planning/prd/PLANNING.md`
2. `.claude/commands/generate-prp.md` - All paths → `.ai/planning/prp/...`
3. `.ai/AGENTS.md` - All 7 path references updated
4. `.ai/context_engineering.md` - Surgically reduced, now points to planning/README.md

### Files Created
- `.ai/planning/README.md` (copied from agent-cece)
- `.ai/planning/templates/PLANNING_TEMPLATE.md`
- `.ai/planning/templates/TASKS_TEMPLATE.md`
- `.ai/planning/prd/PLANNING.md` (test file)
- `scripts/cleanup-old-planning-dirs.sh` (removes old .ai/prd/ and .ai/prp/)

### Additional Changes
- Deleted empty `.ai/context/` folder
- TTS fix: `.claude/hooks/observability/utils/tts/openai_tts.py` (mpv fallback from agent-cece)
- README.md: Added TTS costs, priority, minimal distro setup

## Next Steps

1. **Manual cleanup needed:** Run `./scripts/cleanup-old-planning-dirs.sh` to remove old directories
2. **Test:** Restart Claude Code, run `/convert-planning .ai/scratch/test-plan.md`
3. **Verify:** Check that PLANNING.md is created at `.ai/planning/prd/PLANNING.md`
4. **Commit:** All changes after testing confirms everything works

## Status
- ✅ All files refactored
- ✅ Paths updated in commands and AGENTS.md
- ✅ Structure matches agent-cece
- ⏳ Awaiting manual cleanup of old directories
- ⏳ Awaiting testing
