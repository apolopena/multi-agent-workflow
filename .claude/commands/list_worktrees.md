---
model: claude-sonnet-4-5-20250929
description: List all git worktrees and central observability status
allowed-tools: Bash, Read
---

# Purpose

List all git worktrees in the `trees/` directory with their branch names, directories, and connection status to the central observability server.

## Variables

```
PROJECT_CWD: . (current working directory - the main project root)
WORKTREE_BASE_DIR: trees/
```

## Instructions

- List all worktrees managed by git
- Display comprehensive information in a clear, organized format
- Show central observability server status (one instance for all worktrees)
- Provide commands for worktree management
- Help users understand which worktrees exist and how to access them

## Workflow

### 1. List Git Worktrees

- Get list of all worktrees: `git worktree list`
- Parse output to extract:
  - Worktree path
  - Branch name
  - Commit hash
  - Status (bare, prunable, locked, etc.)
- Separate main repository from worktrees in trees/ directory

### 2. Gather Basic Information

For each worktree:
- Extract branch name from git worktree list output
- Extract directory path
- Get short commit hash: `git log -1 --pretty=format:%h <path>`
- Note: No port configuration or service status needed (centralized observability)

### 3. Check Central Observability Status

Check if central observability server is running (one check for all worktrees):
- Check server port 4000: `lsof -ti :4000`
- Check dashboard port 5173: `lsof -ti :5173`
- If PIDs found, observability is running
- If not found, observability is stopped

### 4. Calculate Statistics

- Total number of worktrees (excluding main repo)
- Central observability status (running or stopped)

### 5. Report

Follow the Report section format below.

## Report

After gathering information, provide a report in the following format:

```
📊 Git Worktrees Overview

═══════════════════════════════════════════════════════════════

📈 Summary:
   Total Worktrees: <count>
   Central Observability: <🟢 RUNNING | 🔴 STOPPED>
   Server: http://localhost:4000
   Dashboard: http://localhost:5173

═══════════════════════════════════════════════════════════════

🌳 Main Repository
   📁 Location: <project-root-path>
   🌿 Branch: <current-branch>
   📝 Commit: <commit-hash-short>

───────────────────────────────────────────────────────────────

🌳 Worktree: <branch-name>
   📁 Location: trees/<branch-name>
   🌿 Branch: <branch-name>
   📝 Commit: <commit-hash-short>

   💡 Actions:
   ├─ Work: cd trees/<branch-name>
   └─ Remove: /remove_worktree <branch-name>

───────────────────────────────────────────────────────────────

[Repeat for each worktree]

═══════════════════════════════════════════════════════════════

🔌 Central Observability Status:

   Server: <🟢 RUNNING (PID: xxxxx) | 🔴 STOPPED>
   Dashboard: <🟢 RUNNING (PID: xxxxx) | 🔴 STOPPED>

   <If running:>
   ✓ All worktrees connected to central server
   ✓ Events from all branches captured in one database
   ✓ View activity: http://localhost:5173

   <If stopped:>
   ⚠️  Start central observability to capture events:
      cd <project-root>
      ./scripts/observability-start.sh

   <Management commands:>
   Start: ./scripts/observability-start.sh
   Stop:  ./scripts/observability-stop.sh
   Status: ./scripts/observability-status.sh

═══════════════════════════════════════════════════════════════

💡 Quick Commands:

Create worktree:
└─ /create_worktree <branch-name>

Remove worktree:
└─ /remove_worktree <branch-name>

Refresh this list:
└─ /list_worktrees

═══════════════════════════════════════════════════════════════
```

If no worktrees exist:

```
📊 Git Worktrees Overview

═══════════════════════════════════════════════════════════════

🌳 Main Repository
   📁 Location: <project-root-path>
   🌿 Branch: <current-branch>
   📝 Commit: <commit-hash-short>

🔌 Central Observability:
   Server: http://localhost:4000 <🟢 RUNNING | 🔴 STOPPED>
   Dashboard: http://localhost:5173 <🟢 RUNNING | 🔴 STOPPED>

═══════════════════════════════════════════════════════════════

ℹ️  No worktrees found in trees/ directory

💡 Create your first worktree for parallel development:
   /create_worktree <branch-name>

   Benefits:
   • Work on multiple branches simultaneously
   • Review PRs without switching contexts
   • Test features in parallel
   • All worktrees share central observability
   • No port conflicts or configuration needed

   Example:
   /create_worktree feature/new-auth
   /create_worktree bugfix/login-error
   /create_worktree hotfix/security-patch

═══════════════════════════════════════════════════════════════
```

If git worktree list fails (not in a git repository):

```
❌ Not a Git Repository

This command requires a git repository.

Make sure you're running this from within a git-managed project.

To initialize a git repository:
└─ git init
```
