# Primer System Test Plan

## Prerequisites
1. ✅ Restart Claude Code to load new agents and commands
2. ✅ Ensure observability system is running (optional, but helpful for monitoring)

---

## Test 0: Setup Script Documentation Feature
**Command:** Run the setup script in a test directory

```bash
# Create a test directory
mkdir -p /tmp/test-observability-setup
cd /tmp/test-observability-setup

# Run setup script
/home/quadro/repos/work/multi-agent-workflow/scripts/observability-setup.sh . test-project
```

**When prompted:** `Continue with installation? (y/N/d for details):`
- Press **'d'** to display documentation

**Expected behavior:**
- Shows "=== Component Details ===" section
- Lists all 5 agents with descriptions:
  - Jerry (summary-processor)
  - Pedro (changelog-manager)
  - Mark (ghcli)
  - Atlas (primer-generator)
  - Bixby (html-converter)
- Lists all slash commands including new primer commands
- Lists all hooks with purposes
- Asks again for confirmation after displaying details

**Verify:**
- All agent names and descriptions are correct
- New primer commands are listed (/generate-context, /generate-arch, /prime-quick, /prime-full)
- Colorized output (green headers)
- Can proceed with 'y' or abort with 'n' after viewing details

**Cleanup:** `rm -rf /tmp/test-observability-setup`

---

## Test Sequence

### Test 1: Generate Context Primer
**Command:** `/generate-context`

**Expected behavior:**
- Reads `.ai/docs/README.md` (documentation URLs)
- Runs git commands (branch, log, status, diff)
- Reads recent CHANGELOG.md entries
- Generates `.ai/scratch/context-primer.md` with:
  - Current branch and goal
  - Recent changes from CHANGELOG
  - Progress checklist (completed/in-progress)
  - Next steps
  - Notes section

**Verify:**
- File created at `.ai/scratch/context-primer.md`
- File is 100-200 lines max
- Contains branch name from git
- Contains recent commits
- Includes CHANGELOG references

---

### Test 2: Generate Architecture Primer
**Command:** `/generate-arch`

**Expected behavior:**
- Analyzes codebase structure
- Generates `.ai/scratch/arch-primer.md` with:
  - Stack overview
  - Directory structure
  - Core patterns
  - How to add features

**Verify:**
- File created at `.ai/scratch/arch-primer.md`
- File is ≤200 lines
- Bullet points only (no prose)
- Covers key architectural elements

---

### Test 3: Full Prime (with Atlas Agent)
**Command:** `/prime-full`

**Expected behavior:**
1. Reads CLAUDE.md
2. Dispatches Atlas agent
3. Atlas executes:
   - Reads CHANGELOG.md
   - Runs `/generate-context`
   - Runs `/generate-arch`
4. Atlas returns confirmation message
5. Main agent reads generated files and presents summary

**Verify:**
- Atlas agent dispatched successfully
- Both context-primer.md and arch-primer.md generated
- Main agent provides synthesis of learned content
- No errors during execution

---

### Test 4: Quick Prime (from existing files)
**Command:** `/prime-quick`

**Expected behavior:**
- Reads CLAUDE.md
- Reads `.ai/scratch/arch-primer.md` in parallel with `.ai/scratch/context-primer.md`
- Reads recent CHANGELOG.md entries
- Presents 100-150 word synthesis with emojis
- Ends with "✅ Primed and ready to work!"

**Verify:**
- Executes quickly (<5 seconds)
- Doesn't regenerate files (uses existing)
- Provides concise, useful summary
- If files missing, errors and tells user to run `/prime-full`

---

### Test 5: Quick Prime Error Handling
**Setup:** Delete `.ai/scratch/context-primer.md`

**Command:** `/prime-quick`

**Expected behavior:**
- Detects missing file
- Errors gracefully
- Instructs user to run `/prime-full` first

**Cleanup:** Run `/prime-full` to regenerate files

---

### Test 6: HTML Converter (Bixby Agent)
**Setup:** Create a test markdown file in root:
```bash
echo "# Test Document\n\nThis is a test.\n\n## Section 1\nContent here." > test.md
```

**Command:** "Convert test.md to HTML" or "Format test.md as HTML"

**Expected behavior:**
1. Bixby agent dispatched
2. Reads test.md
3. Generates test.html with:
   - Dark mode styling
   - Collapsible TOC sidebar
   - Theme toggle button
   - Responsive design

**Verify:**
- test.html created
- Open in browser: clean, styled HTML
- TOC works (toggle button)
- Theme toggle works (persists to localStorage)
- Dark mode is default

**Cleanup:** `rm test.md test.html`

---

## Success Criteria

✅ **All agents load without errors**
✅ **Commands execute without failures**
✅ **Generated files follow specifications**
✅ **Atlas integration works end-to-end**
✅ **Primers written to `.ai/scratch/` (gitignored)**
✅ **Primer naming convention used (context-primer.md, arch-primer.md)**
✅ **CHANGELOG.md replaces progress.md successfully**

---

## Notes for Manual Testing

- Watch for path errors (should be `.ai/scratch/` for primers, `.ai/docs/` for documentation)
- Verify CHANGELOG.md is read (not progress.md)
- Check that `.ai/docs/README.md` is referenced in generate-context
- Ensure agent names are capitalized (Atlas, Bixby)
- Monitor for any hardcoded Peachy DevOps paths

---

## Rollback Plan (if needed)

If tests fail critically:
1. Check git status: `git status`
2. Review changes: `git diff`
3. Revert if needed: `git checkout -- .claude/`
4. Report specific errors for debugging
