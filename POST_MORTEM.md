# Post-Mortem: Infrastructure Fixes & Project Name Refactor

**Date:** 2025-10-28
**Session Duration:** ~2 hours
**Branch:** `feat/infrastructure-updates`

## Executive Summary

Fixed three major infrastructure issues that prevented smooth installation and usage:
1. Hardcoded project names breaking portability
2. Bun binary not accessible to coding assistants
3. Missing directory structure causing SQLite errors

All issues resolved, tested, and documented.

---

## Issues Identified & Fixed

### 1. Hardcoded Project Name Issue

**Problem:**
- `--source-app cc-hook-multi-agent-obvs` was hardcoded in all hook commands in `settings.json`
- When users ran `observability-setup.sh` on other projects, the setup script tried to replace this hardcoded name
- Not scalable or clean - project name should be configured once, not embedded in every hook command

**Root Cause:**
- Originally designed with hardcoded project name in hook commands
- `.observability-config` existed but didn't store `PROJECT_NAME`
- `send_event.py` required `--source-app` as a command-line argument

**Solution Implemented:**

1. **Modified `send_event.py`** (`.claude/hooks/observability/send_event.py`):
   - Made `--source-app` optional (was required)
   - Added logic to read `PROJECT_NAME` from `.observability-config`
   - Fallback hierarchy: CLI arg > config file > directory name

2. **Updated `settings.json` template** (`.claude/settings.json`):
   - Removed ALL instances of `--source-app cc-hook-multi-agent-obvs`
   - Now hooks call: `send_event.py --event-type <TYPE>` (no source-app needed)

3. **Enhanced `observability-setup.sh`**:
   - Added `PROJECT_NAME` field to generated `.observability-config`
   - Removed obsolete string replacement logic (`gsub("cc-hook-multi-agent-obvs"; $name)`)
   - Config now properly stores project name during installation

4. **Created `.observability-config.template`**:
   - Added to `templates/` directory
   - Users copy this for local development in the multi-agent-workflow repo itself
   - Contains: `PROJECT_NAME`, `MULTI_AGENT_WORKFLOW_PATH`, `SERVER_URL`, `CLIENT_URL`

**Testing:**
- ✅ Sent manual test event - confirmed `source_app: "multi-agent-workflow"` read from config
- ✅ Ran setup script in test directory - created config with custom project name
- ✅ Verified no hardcoded names in generated settings.json
- ✅ Grep confirmed only backup files contain old hardcoded name

---

### 2. Bun Binary Accessibility Issue

**Problem:**
- `start-system.sh` called `bun run dev` directly
- Bun installed to `~/.bun/bin/bun` by default installer
- Coding assistants spawn non-interactive shells that don't load `.bashrc`/`.zshrc`
- Bun's PATH additions in shell config files not available to assistant shells
- Result: `bun: command not found` errors

**Root Cause:**
- Bun installer adds `~/.bun/bin` to PATH via shell config modifications
- UV installer directly places binary in `~/.local/bin` (already in system PATH)
- Different installation approaches led to inconsistent availability

**Solution Implemented:**

1. **Created symlink** (one-time user action):
   ```bash
   ln -s ~/.bun/bin/bun ~/.local/bin/bun
   ```
   - `~/.local/bin` already in system PATH
   - Works for all shells (interactive and non-interactive)
   - No script modifications needed

2. **Updated README** (line 46-57):
   - Added clear "Make binaries accessible to coding assistants" section
   - Explained WHY this is needed (non-interactive shells)
   - Provided instructions for custom install locations (`$BUN_INSTALL`)
   - Added note about UV (already works, but documented for completeness)

**Testing:**
- ✅ Verified `which bun` returns `/home/quadro/.local/bin/bun`
- ✅ Confirmed `bun --version` works (v1.3.1)
- ✅ `start-system.sh` successfully started both server and client
- ✅ No "command not found" errors

---

### 3. Missing Directory Structure (SQLite Error)

**Problem:**
- Server failed to start with: `SQLiteError: unable to open database file` for `settings.db`
- `apps/server/data/` directory missing from fresh clones
- `.gitignore` ignores `*.db` files, but directory itself not tracked
- No `.gitkeep` file to preserve empty directory in git

**Root Cause:**
- Directory created manually during development but never committed
- SQLite can't create database if parent directory doesn't exist
- Common git issue with empty directories

**Solution Implemented:**

1. **Added `.gitkeep` files**:
   - `apps/server/data/.gitkeep` - for SQLite databases
   - `logs/.gitkeep` - for application logs

2. **Staged for commit**:
   ```bash
   git add -f apps/server/data/.gitkeep
   git add -f logs/.gitkeep
   ```

**Testing:**
- ✅ Stopped and restarted system
- ✅ Server started successfully with no SQLite errors
- ✅ Both databases created: `settings.db` and event database
- ✅ Server responded to `/events/filter-options` endpoint

---

### 4. Template Files Organization (Bonus Fix)

**Problem:**
- Template files scattered in repo root: `.env.sample`, `.mcp.json.firecrawl_7k.sample`
- Inconsistent naming convention (`.sample` suffix)
- No central location for template files

**Solution Implemented:**

1. **Created `templates/` directory**:
   - Centralized location for all template files
   - Cleaner repo structure

2. **Renamed and moved files**:
   - `.env.sample` → `templates/.env.template`
   - `apps/client/.env.sample` → `templates/client.env.template`
   - `.mcp.json.firecrawl_7k.sample` → `templates/mcp-firecrawl.json.template`
   - Created `templates/.observability-config.template`

3. **Updated documentation**:
   - README now references `templates/` directory
   - Setup instructions use new paths

---

## Files Modified

### Core Logic Changes
- `.claude/hooks/observability/send_event.py` - Made --source-app optional, read from config
- `.claude/settings.json` - Removed all hardcoded --source-app parameters
- `scripts/observability-setup.sh` - Added PROJECT_NAME to config, removed replacement logic

### Documentation
- `README.md` - Added bun symlink instructions, updated template references, added config setup step

### New Files
- `templates/.env.template` (moved)
- `templates/client.env.template` (moved)
- `templates/mcp-firecrawl.json.template` (moved)
- `templates/.observability-config.template` (created)
- `apps/server/data/.gitkeep` (created)
- `logs/.gitkeep` (created)

### Backup Files (for reference)
- `.claude/settings.json.backup-refactor` - Pre-change backup

---

## Testing Summary

### Manual Tests Performed

1. **Project Name Refactor**:
   - ✅ Manual event send with no --source-app: `source_app: "multi-agent-workflow"`
   - ✅ Setup script creates config with custom project name
   - ✅ No grep matches for hardcoded name (except backups)

2. **Bun Accessibility**:
   - ✅ Symlink created: `~/.local/bin/bun → ~/.bun/bin/bun`
   - ✅ `which bun` returns correct path
   - ✅ `bun --version` works
   - ✅ Scripts find and execute bun successfully

3. **System Startup**:
   - ✅ Server starts without SQLite errors
   - ✅ Client starts successfully
   - ✅ Both services respond on expected ports (4000, 5173)

4. **Setup Script**:
   - ✅ Tested in clean directory `/tmp/test-observability-setup`
   - ✅ Creates proper config with PROJECT_NAME
   - ✅ Settings.json has no --source-app parameters
   - ✅ All required files and directories created

---

## Design Decisions

### 1. Why Config File Over Environment Variable?

**Decision:** Store `PROJECT_NAME` in `.observability-config` instead of environment variable.

**Rationale:**
- Already have config file for other settings
- Single source of truth
- Easier to debug (just read the file)
- Consistent with other config values

### 2. Why Symlink Over Script Modification?

**Decision:** User creates symlink instead of modifying scripts to find bun.

**Rationale:**
- One-time user action vs complex PATH detection logic
- Works for all scripts, not just ours
- Simpler maintenance
- Standard Unix/Linux approach
- Users might need bun accessible anyway

### 3. Why Remove --source-app Instead of Keep Both?

**Decision:** Remove --source-app parameter entirely, make it config-only.

**Rationale:**
- Single source of truth principle
- Reduces complexity in hook commands
- No risk of CLI arg conflicting with config
- Cleaner settings.json template
- Easier to understand and maintain

---

## Potential Issues & Considerations

### 1. Existing Installations
**Issue:** Users who already ran `observability-setup.sh` on other projects will have old settings.json with hardcoded names.

**Solution:**
- They need to re-run `observability-setup.sh` after pulling latest changes
- Or manually remove `--source-app` from their settings.json
- Should document in CHANGELOG

### 2. Bun Installation Location
**Issue:** If users install bun with `BUN_INSTALL` env var to custom location, symlink command won't work.

**Solution:**
- Documented in README with alternative command
- Users need to adjust: `ln -s $BUN_INSTALL/bin/bun ~/.local/bin/bun`

### 3. Multiple Developers Same Machine
**Issue:** Different developers might want different multi-agent-workflow paths.

**Solution:**
- `.observability-config` is gitignored (environment-specific)
- Each developer creates their own after cloning
- Template provides starting point

---

## Lessons Learned

### What Went Well
1. **Systematic debugging** - Identified root causes before jumping to solutions
2. **Testing methodology** - Tested each fix in isolation before moving on
3. **Documentation-first** - Updated README immediately after fixes
4. **Clean git history** - Used proper staging, avoided force pushes

### What Could Be Improved
1. **Directory tracking** - Should have caught missing .gitkeep files earlier
2. **Installation testing** - Need automated tests for fresh clone scenario
3. **Pre-commit hooks** - Could have caught the hardcoded name issue

### Recommendations
1. Add automated test: `./scripts/test-fresh-install.sh` that simulates fresh clone
2. Add CI check for hardcoded project names
3. Document the "restart Claude Code" requirement more prominently
4. Consider adding setup verification step: `./scripts/verify-setup.sh`

---

## Current State

### System Status
- ✅ All background processes running successfully
- ✅ Server: http://localhost:4000 (responding)
- ✅ Client: http://localhost:5173 (responding)
- ✅ WebSocket: ws://localhost:4000/stream (connected)

### Uncommitted Changes
```
Changes to be committed:
  new file:   apps/server/data/.gitkeep
  new file:   logs/.gitkeep

Changes not staged for commit:
  modified:   .claude/settings.json
  modified:   README.md
  modified:   scripts/observability-setup.sh

Untracked files:
  templates/
  .claude/.observability-config
  POST_MORTEM.md
```

### Next Steps
1. Review this post-mortem
2. Test in a completely fresh environment (new VM or container)
3. Update CHANGELOG.md with all changes
4. Commit changes with appropriate message
5. Consider creating GitHub issue to track testing with new users

---

## Technical Debt

### Identified During This Session
1. **Hook blocking logic too aggressive** - Pre-tool-use hook blocks `.env.sample` operations
2. **Script error messages** - Could be more helpful (e.g., suggest symlink when bun not found)
3. **No automated setup verification** - Users don't know if setup succeeded until they try it

### Not Addressed (Future Work)
1. Make pre-tool-use hook smarter about .sample file operations
2. Add `--verify` flag to observability-setup.sh
3. Consider creating a "doctor" command to diagnose installation issues
4. Add more comprehensive error messages to send_event.py

---

## Appendix: Command Reference

### Verify Bun Accessibility
```bash
which bun                    # Should return: /home/<user>/.local/bin/bun
bun --version               # Should return version number
```

### Verify Project Name Config
```bash
cat .claude/.observability-config | jq '.PROJECT_NAME'
```

### Test Send Event Manually
```bash
echo '{"session_id": "test-123", "tool_name": "Test", "tool_input": {}}' | \
  uv run .claude/hooks/observability/send_event.py --event-type PreToolUse
```

### Check Recent Events
```bash
curl -s "http://localhost:4000/events/recent?limit=5" | jq '.[] | {source_app, session_id}'
```

### Re-run Setup Script
```bash
/path/to/multi-agent-workflow/scripts/observability-setup.sh . <PROJECT_NAME>
```

---

**End of Post-Mortem**
