---
model: claude-sonnet-4-5-20250929
description: Create a git worktree for parallel development with central observability
argument-hint: <branch-name>
allowed-tools: Bash, Read, Glob
---

# Purpose

Create a new git worktree in the `trees/` directory for parallel development. Each worktree shares the centralized observability system running in the main repository, ensuring all events are captured in one place without port conflicts or data fragmentation.

## Variables

```
PROJECT_CWD: . (current working directory - the main project root)
BRANCH_NAME: $1 (required)
WORKTREE_BASE_DIR: trees/
WORKTREE_DIR: trees/<BRANCH_NAME>
```

## Instructions

- Creates a git worktree in `trees/<BRANCH_NAME>/` for parallel development
- Worktree uses the SAME centralized observability server/dashboard from main repo
- No worktree-specific .claude/ directory needed (inherits from parent via upward search)
- No separate ports, databases, or services per worktree
- All observability events from all worktrees go to central server at http://localhost:4000
- All data stored in main repo's `.claude/data/observability/`
- If branch doesn't exist locally, create it from current HEAD
- If branch exists but isn't checked out, create worktree from it
- Worktrees are perfect for testing multiple features, reviewing PRs, or hot-fixing while developing

## Workflow

### 1. Parse and Validate Arguments

- Read BRANCH_NAME from $1
- If missing, error with usage: `/create_worktree <branch-name>`
- Validate branch name format (no spaces, valid git branch name characters)
- Construct WORKTREE_DIR path: `PROJECT_CWD/trees/<BRANCH_NAME>`

### 2. Pre-Creation Validation

- Check if `trees/` directory exists
  - If not, create it: `mkdir -p trees/`
  - Add to .gitignore if not already present: `echo '/trees/' >> .gitignore`
- Check if worktree already exists for this branch
  - Run: `git worktree list`
  - If worktree exists at `trees/<BRANCH_NAME>`, error with message
- Check if branch exists
  - Run: `git branch --list <BRANCH_NAME>`
  - If doesn't exist, note that it will be created from current HEAD

### 3. Create Git Worktree

- Create the worktree:
  ```bash
  git worktree add trees/<BRANCH_NAME> <BRANCH_NAME>
  ```
- If branch doesn't exist, git will create it automatically
- Verify creation successful: `git worktree list | grep trees/<BRANCH_NAME>`

### 4. Validation

- Confirm WORKTREE_DIR exists as a directory
- Confirm git recognizes it: `git worktree list`
- Confirm .git file exists in worktree (links to main repo)

### 5. Report

Follow the Report section format below to provide comprehensive worktree information.

## Report

After successful worktree creation, provide a report in the following format:

```
✅ Git Worktree Created Successfully!

📁 Worktree Details:
   Location: trees/<BRANCH_NAME>
   Branch: <BRANCH_NAME>
   Status: ✓ Ready for development

🔌 Central Observability:
   This worktree shares the centralized observability system.

   Server: http://localhost:4000
   Dashboard: http://localhost:5173

   ⚠️  IMPORTANT: Ensure central observability is running:
      cd <PROJECT_CWD>
      ./scripts/observability-start.sh

   All events from this worktree will be captured centrally.
   Events are identified by: source_app + session_id

📝 Usage:
   1. Work in the worktree:
      cd trees/<BRANCH_NAME>

   2. Open Claude Code or work normally
      - Hooks will automatically connect to central server
      - No separate configuration needed
      - Data stored in main repo's .claude/data/

   3. View events in central dashboard:
      http://localhost:5173

   4. All worktrees + main repo share:
      - Same observability server (port 4000)
      - Same dashboard (port 5173)
      - Same events database
      - Same session logs

🗑️  To Remove This Worktree:
   /remove_worktree <BRANCH_NAME>

   Or manually:
   git worktree remove trees/<BRANCH_NAME>

📋 List All Worktrees:
   /list_worktrees

💡 Key Points:
   • No .claude/ directory needed in worktree (inherits from main repo)
   • No separate ports or services to manage
   • All data centralized in main repo
   • Perfect for parallel development without complexity
```

If any warnings occurred during creation:

```
⚠️  Warnings / Notes:
- Branch '<BRANCH_NAME>' was created from current HEAD
- [Any other relevant warnings]
```

If worktree already exists:

```
❌ Worktree Creation Failed

⚠️  Worktree 'trees/<BRANCH_NAME>' already exists for branch '<BRANCH_NAME>'

To use it:
└─ cd trees/<BRANCH_NAME>

To remove and recreate:
└─ /remove_worktree <BRANCH_NAME>
└─ /create_worktree <BRANCH_NAME>

To list all worktrees:
└─ /list_worktrees
```

If branch name is invalid:

```
❌ Invalid Branch Name

Branch name '<BRANCH_NAME>' contains invalid characters.

Valid branch names:
• No spaces
• No special characters like ~, ^, :, ?, *, [
• Can contain letters, numbers, hyphens, underscores, forward slashes

Examples of valid names:
• feature/new-auth
• bugfix/login-error
• hotfix-123

Try again with:
└─ /create_worktree <valid-branch-name>
```
