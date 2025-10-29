# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### PR #3 - Infrastructure Updates
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** 🟡 Open

- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **FIX:** *config*
  - Remove hardcoded project names, read from `.observability-config` dynamically
- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **FIX:** *setup*
  - Add missing directory structure with `.gitkeep` files in `apps/server/data/` and `logs/`
- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **DOCS:** *setup*
  - Document bun binary accessibility with symlink creation for non-interactive shells
- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **CHORE:** *templates*
  - Move all template files to `templates/` directory with `.template` extension
- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **DOCS:** *postmortem*
  - Add comprehensive root cause analysis with solutions and testing
- [[a9ffd3e](https://github.com/apolopena/multi-agent-workflow/commit/a9ffd3e)] **DOCS:** *changelog*
  - Update CHANGELOG with commit hash
- [[10d8e24](https://github.com/apolopena/multi-agent-workflow/commit/10d8e24)] **DOCS:** *agent*
  - Add anti-pattern examples to Pedro instructions
- [[75e462b](https://github.com/apolopena/multi-agent-workflow/commit/75e462b)] **FEAT:** *agent*
  - Add mandatory verification step to Pedro
- [[fc60a00](https://github.com/apolopena/multi-agent-workflow/commit/fc60a00)] **REFACTOR:** *agent*
  - Update verification to check only added commits
- [[96ab734](https://github.com/apolopena/multi-agent-workflow/commit/96ab734)] **CHORE:** *config*
  - Add gitignore rules and update CHANGELOG

---

## [v1.0.1] - 2025-10-25

### [PR #2](https://github.com/apolopena/multi-agent-workflow/pull/2) - Config System, Dynamic Wrappers, and Unified Setup
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[cdee9ff](https://github.com/apolopena/multi-agent-workflow/commit/cdee9ff)] **FEAT:** *setup*
  - Add automated setup script with pre-flight checks and dynamic wrapper generation
- [[3bb6e4e](https://github.com/apolopena/multi-agent-workflow/commit/3bb6e4e)] **FEAT:** *config*
  - Add observability configuration system with `.observability-config` and state files
- [[00c3363](https://github.com/apolopena/multi-agent-workflow/commit/00c3363)] **FEAT:** *config*
  - Add bash config loader utility for shell scripts
- [[3bb6e4e](https://github.com/apolopena/multi-agent-workflow/commit/3bb6e4e)] **REFACTOR:** *hooks*
  - Move all hooks to `.claude/hooks/observability/` subdirectory
- [[00c3363](https://github.com/apolopena/multi-agent-workflow/commit/00c3363)] **REFACTOR:** *hooks*
  - Update hardcoded paths to use config-based paths
- [[01c676b](https://github.com/apolopena/multi-agent-workflow/commit/01c676b)] **DOCS:** *readme*
  - Complete overhaul with unified setup guide and architecture documentation
- [[206001a](https://github.com/apolopena/multi-agent-workflow/commit/206001a)] **DOCS:** *changelog*
  - Add initial `CHANGELOG.md` file
- [[cdee9ff](https://github.com/apolopena/multi-agent-workflow/commit/cdee9ff)] **CHORE:** *naming*
  - Standardize script names with `observability-*` prefix

---

## [v1.0.0] - 2025-10-20

### [PR #1](https://github.com/apolopena/multi-agent-workflow/pull/1) - Initial Infrastructure and Workflow Enhancements
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[57b12e2](https://github.com/apolopena/multi-agent-workflow/commit/57b12e2)] **FEAT:** *agent*
  - Add Kim agent for observability system management with enable/disable capabilities
- [[aadfe1a](https://github.com/apolopena/multi-agent-workflow/commit/aadfe1a)] **FEAT:** *ui*
  - Add theme system with custom theme creation and import/export functionality
- [[aadfe1a](https://github.com/apolopena/multi-agent-workflow/commit/aadfe1a)] **FEAT:** *hitl*
  - Add human-in-the-loop WebSocket system for agent interactions
- [[a627337](https://github.com/apolopena/multi-agent-workflow/commit/a627337)] **FEAT:** *api*
  - Add user preferences management with SQLite backend and REST API
- [[a627337](https://github.com/apolopena/multi-agent-workflow/commit/a627337)] **FEAT:** *ui*
  - Add summary generation UI with client-side button and workflow
- [[a627337](https://github.com/apolopena/multi-agent-workflow/commit/a627337)] **FIX:** *security*
  - Add `.env` file protection with access rules in pre-tool-use hook
- [[275a6c7](https://github.com/apolopena/multi-agent-workflow/commit/275a6c7)] **FIX:** *git*
  - Add SSH key integration via `git-ai.sh` script with keychain support
- [[5db4e33](https://github.com/apolopena/multi-agent-workflow/commit/5db4e33)] **FIX:** *env*
  - Fix env config and add summary improvements
- [[275a6c7](https://github.com/apolopena/multi-agent-workflow/commit/275a6c7)] **DOCS:** *claude*
  - Add `git-ai.sh` usage instructions and Mark agent policy to `CLAUDE.md`
- [[275a6c7](https://github.com/apolopena/multi-agent-workflow/commit/275a6c7)] **DOCS:** *claude*
  - Add git branch/status display in Claude Code status bar
- [[e12a829](https://github.com/apolopena/multi-agent-workflow/commit/e12a829)] **DOCS:** *env*
  - Document `ELEVENLABS_VOICE_ID` environment variable
- [[0b2c497](https://github.com/apolopena/multi-agent-workflow/commit/0b2c497)] **DOCS:** *setup*
  - Add `mpv` dependency to prerequisites
- [[7571bd6](https://github.com/apolopena/multi-agent-workflow/commit/7571bd6)] **DOCS:** *branding*
  - Add attribution to original author
- [[4bce248](https://github.com/apolopena/multi-agent-workflow/commit/4bce248)] **DOCS:** *branding*
  - Reposition as complete workflow system with agents
