# Claude Code Multi Agent Observability

## Instructions
> Follow these instructions as you work through the project.

### 📝 Commit Messages
<60 chars, brief, imperative mood

### CRITICAL: SSH Git Commands
ALWAYS use `./scripts/git-ai.sh` for git commands requiring SSH (commit, push, pull, fetch, clone, remote, ls-remote, submodule). Prevents SSH askpass errors via keychain + adds AI attribution.

### REMEMBER: Use source_app + session_id to uniquely identify an agent.

Every hook event will include a source_app and session_id. Use these to uniquely identify an agent.
For display purposes, we want to show the agent ID as "source_app:session_id" with session_id truncated to the first 8 characters.