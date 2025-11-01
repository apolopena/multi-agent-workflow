# Prime Command Optimization TODO

## Problem
Current `/prime-full` takes ~6 minutes due to CHANGELOG analysis of 100+ commit entries. Original fork's `/prime` was 10-30 seconds and sufficient for most work.

## Solution - Command Restructure

### `/prime` (New - Simple & Fast)
The original approach - becomes the default:
- `git ls-files` - See what exists
- Read `README.md` - Comprehensive overview (780 lines covers everything)
- Read `.ai/docs/README.md` - Available docs
- Target: 10-30 seconds
- **This is what current `/prime-quick` should become**

### `/prime-full` (Read Existing Primers)
What current `/prime-quick` does:
- Read existing `.ai/scratch/context-primer.md`
- Read existing `.ai/scratch/arch-primer.md`
- Target: <5 seconds
- **Current `/prime-quick` becomes `/prime-full`**

### `/prime-deep` (Comprehensive Analysis)
What current `/prime-full` does:
- Generate fresh primers with Atlas
- Read CHANGELOG with 100+ commit analysis
- Deep context generation (300-400 lines)
- Use cases: returning after long absence, onboarding, documentation writing
- Target: 6 minutes (acceptable for deep analysis)
- **Current `/prime-full` becomes `/prime-deep`**

## Reasoning
README is comprehensive enough for 80% of work sessions. Deep CHANGELOG analysis is overkill for daily work but valuable occasionally.

## Files to Modify

1. **Create** `.claude/commands/prime.md` - New simple/fast command (original approach)
2. **Rename** `.claude/commands/prime-quick.md` → `prime-full.md` (just rename)
3. **Rename** `.claude/commands/prime-full.md` → `prime-deep.md` (just rename)
4. **Update** `.claude/agents/primer-generator.md` - Atlas instructions if needed

## Original Approach (Reference)
```
Run: git ls-files
Read: @README.md
Read and Execute: @ai_docs/README.md
```
