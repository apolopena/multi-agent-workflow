# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

---

## [v2.0.0] - 2025-11-12

### [PR #16](https://github.com/apolopena/multi-agent-workflow/pull/16) - Major Refactor: Observability System Architecture
**Branch:** `major-refactor` → `main` · **Status:** ✅ Merged

#### Breaking Changes
- **Directory Structure:** All observability data moved from `logs/` to `.claude/data/observability/`
  - Sessions: `.claude/data/observability/sessions/SESSION_ID.json`
  - Logs: `.claude/data/observability/logs/SESSION_ID/`
  - Backups: `.claude/data/observability/transcript_backups/`
- **Path Resolution:** Removed `Path.cwd()` usage; all hooks now use `get_project_root()` for consistent path resolution
- **Aggregate Logging:** Removed redundant aggregate log files (`session_start.json`, `session_end.json`, etc.)

#### Features
- [[7b9a903](https://github.com/apolopena/multi-agent-workflow/commit/7b9a903)] **FEAT:** *infrastructure*
  - Implement centralized `.env` loading system with `load_central_env()` for hooks and utilities (WP-REF-1)
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **FEAT:** *fallback*
  - Add TTS fallback chain (ElevenLabs → OpenAI → pyttsx3) with server reachability checks (WP-REF-2)
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **FEAT:** *api-key*
  - Implement API key fallback for summaries (Anthropic → OpenAI) with graceful error handling and voice warnings (WP-REF-2)
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **FEAT:** *performance*
  - Add server reachability check in `send_event.py` to prevent wasted API quota before summary generation

#### Bug Fixes
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **FIX:** *tts*
  - Fix OpenAI TTS error handling to properly exit with error code on API failures (was silently succeeding)
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **FIX:** *paths*
  - Fix status line and hooks to find session data from any subdirectory using `get_project_root()`

#### Refactoring
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **REFACTOR:** *paths*
  - Consolidate observability data under `.claude/data/observability/` with `get_project_root()` utility (WP-REF-3)
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **REFACTOR:** *logging*
  - Remove redundant aggregate logging functions from `session_end.py`, `session_start.py`, and `user_prompt_submit.py`
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **REFACTOR:** *cleanup*
  - Remove debug logging from `utils/llm/oai.py` (/tmp/oai_debug.log)

#### Configuration
- [[466c937](https://github.com/apolopena/multi-agent-workflow/commit/466c937)] **CHORE:** *gitignore*
  - Clean up `.gitignore` for new observability paths under `.claude/data/` and add `.ai/scratch/`
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **CHORE:** *config*
  - Update `templates/.observability-config.template` to clarify multi-agent-workflow path usage
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **CHORE:** *scripts*
  - Update enable/disable scripts to use central repo path for state file

#### Documentation
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **DOCS:** *setup*
  - Document `git-ai.sh` installation and copying during setup in `README.md`
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **DOCS:** *template*
  - Add `templates/.env.template` for central configuration

#### Performance
- [[b8fbb81](https://github.com/apolopena/multi-agent-workflow/commit/b8fbb81)] **PERF:** *tts*
  - Reduce pyttsx3 speech rate from 180 to 140 wpm for improved clarity

---

## [v1.0.9] - 2025-11-06

### [PR #14](https://github.com/apolopena/multi-agent-workflow/pull/14) - Optimize Mark and Pedro agent prompts for speed
**Branch:** `refactor/optimize-agent-prompts` → `main` · **Status:** ✅ Merged

- [[29365de](https://github.com/apolopena/multi-agent-workflow/commit/29365de)] **REFACTOR:** *agent*
  - Optimize Mark and Pedro agent prompts to reduce token usage and execution time

---

## [v1.0.8] - 2025-11-06

### [PR #12](https://github.com/apolopena/multi-agent-workflow/pull/12) - Remove hardcoded userinfo from .ssh deny paths
**Branch:** `fix/remove-hardcoded-userinfo-from-settings` → `main` · **Status:** ✅ Merged

- [[1087b8b](https://github.com/apolopena/multi-agent-workflow/commit/1087b8b)] **FIX:** *security*
  - Remove hardcoded userinfo from `.ssh` deny paths in `.claude/settings.json`

---

## [v1.0.7] - 2025-11-06

### [PR #11](https://github.com/apolopena/multi-agent-workflow/pull/11) - Add GitHub provenance workflow to setup script and document requirements
**Branch:** `feat/update-setup-script-provenance` → `main` · **Status:** ✅ Merged

- [[8f317a0](https://github.com/apolopena/multi-agent-workflow/commit/8f317a0)] **FEAT:** *setup*
  - Add GitHub provenance workflow to setup script with directory creation and pre-flight checks
- [[d4ec1eb](https://github.com/apolopena/multi-agent-workflow/commit/d4ec1eb)] **DOCS:** *setup*
  - Add GitHub provenance setup documentation with required secrets list

---

## [v1.0.6] - 2025-11-04

### [PR #9](https://github.com/apolopena/multi-agent-workflow/pull/9) - Context Engineering System
**Branch:** `feat/context-engineering-system` → `main` · **Status:** ✅ Merged

- [[e94f21f](https://github.com/apolopena/multi-agent-workflow/commit/e94f21f)] **FEAT:** *infrastructure*
  - Add Context Engineering system and templates
- [[093d600](https://github.com/apolopena/multi-agent-workflow/commit/093d600)] **FEAT:** *planning*
  - Add hybrid Linear/Parallel planning system with mode selection in `/convert-planning` command
- [[2b50c28](https://github.com/apolopena/multi-agent-workflow/commit/2b50c28)] **FEAT:** *setup*
  - Add `CLAUDE.md` installation with backup to `observability-setup.sh`

---

## [v1.0.5] - 2025-10-30

### [PR #8](https://github.com/apolopena/multi-agent-workflow/pull/8) - Enhance setup script with comprehensive overwrite warnings
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[8f0f790](https://github.com/apolopena/multi-agent-workflow/commit/8f0f790)] **FEAT:** *setup*
  - Enhance setup script with comprehensive overwrite warnings listing all affected files and categorized summary

---

## [v1.0.4] - 2025-10-30

### [PR #7](https://github.com/apolopena/multi-agent-workflow/pull/7) - Fix summary UX, .env loading, Atlas and Bixby agents
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FEAT:** *ui*
  - Simplified summary generation with one-button operation hardcoded to repo root
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FIX:** *server*
  - Fixed `.env` loading by running server from project root instead of `apps/server`
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FEAT:** *agent*
  - Add Atlas agent for generating `context.md` and `architecture.md` documentation
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FEAT:** *agent*
  - Add Bixby agent for HTML formatting operations
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FEAT:** *database*
  - Implement project registration with database persistence
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **REFACTOR:** *docs*
  - Reorganize documentation by moving `ai_docs` to `.ai/docs`
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **CHORE:** *cleanup*
  - Remove `demo-cc-agent` directory and obsolete test/benchmark files
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FIX:** *changelog*
  - Fix CHANGELOG version ordering to use proper semantic version sort
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **FEAT:** *commands*
  - Update `generate-context` command with improved functionality
- [[22006ad](https://github.com/apolopena/multi-agent-workflow/commit/22006ad)] **CHORE:** *config*
  - Clean up `.claude` configuration by removing deprecated agents and commands

---

## [v1.0.3] - 2025-10-29

### [PR #6](https://github.com/apolopena/multi-agent-workflow/pull/6) - Add Pedro changelog manager with verification
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[1e69a37](https://github.com/apolopena/multi-agent-workflow/commit/1e69a37)] **FEAT:** *agent*
  - Add Pedro changelog manager with automated verification to prevent duplicate entries

---

## [v1.0.2] - 2025-10-28

### [PR #3](https://github.com/apolopena/multi-agent-workflow/pull/3) - Infrastructure Updates
**Branch:** `feat/infrastructure-updates` → `main` · **Status:** ✅ Merged

- [[a1122f0](https://github.com/apolopena/multi-agent-workflow/commit/a1122f0)] **FIX:** *infrastructure*
  - Fix critical infrastructure issues and refactor project config
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
