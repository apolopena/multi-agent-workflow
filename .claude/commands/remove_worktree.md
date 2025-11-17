---
model: claude-sonnet-4-5-20250929
description: Remove a git worktree and delete its branch
argument-hint: <branch-name>
allowed-tools: Bash, Read, Glob
---

# Purpose

Remove an existing git worktree from the `trees/` directory AND delete the associated git branch. This ensures complete cleanup without orphaned directories or branches.

## Variables

```
PROJECT_CWD: . (current working directory - the main project root)
BRANCH_NAME: $1 (required)
WORKTREE_DIR: trees/<BRANCH_NAME>
```

## Instructions

- This command safely removes a worktree and all associated resources
- Removes the git worktree using git's built-in removal command
- Deletes the git branch associated with the worktree (PERMANENT)
- Validates that the worktree and branch were completely removed
- Provides clear feedback about what was removed and any issues encountered
- Handles cases where worktree is already partially removed
- WARNING: Both worktree and branch deletion are permanent and cannot be undone

## Workflow

### 1. Parse and Validate Arguments

- Read BRANCH_NAME from $1, error if missing
- Construct WORKTREE_DIR path: `PROJECT_CWD/trees/<BRANCH_NAME>`
- Validate branch name format (no spaces, valid git branch name)

### 2. Check Worktree Existence

- List all worktrees: `git worktree list`
- Check if worktree exists at WORKTREE_DIR
- If worktree doesn't exist:
  - Check if directory exists anyway (orphaned directory)
  - If directory exists, note it for manual cleanup
  - If neither exists, error with message that worktree not found

### 3. Remove Git Worktree

- Remove worktree using git: `git worktree remove trees/<BRANCH_NAME>`
- If removal fails with error (e.g., worktree has uncommitted changes):
  - Try force removal: `git worktree remove trees/<BRANCH_NAME> --force`
  - Note the force removal in the report
- Verify worktree was removed: `git worktree list | grep trees/<BRANCH_NAME>`
- Should return nothing if successfully removed

### 4. Clean Up Orphaned Files

- Check if WORKTREE_DIR still exists after git worktree remove
- If directory still exists (shouldn't, but possible with force):
  - Note this in warnings
  - Do NOT automatically delete with rm -rf (security)
  - Provide manual cleanup instructions

### 5. Delete Git Branch

- After worktree is successfully removed, delete the git branch:
  - First try safe delete: `git branch -d <BRANCH_NAME>`
  - If safe delete fails (unmerged changes), use force delete: `git branch -D <BRANCH_NAME>`
  - Note in report if force delete was used
- Verify branch was deleted: `git branch --list <BRANCH_NAME>`
- Should return nothing if successfully deleted
- Important: This is destructive and permanent

### 6. Validation

- Confirm worktree no longer appears in: `git worktree list`
- Confirm directory no longer exists at WORKTREE_DIR
- Confirm branch no longer exists: `git branch --list <BRANCH_NAME>`
- If any validation fails, include in warnings section

### 7. Report

Follow the Report section format below to provide comprehensive removal information.

## Report

After successful worktree removal, provide a detailed report in the following format:

```
✅ Git Worktree and Branch Removed Successfully!

📁 Worktree Details:
   Location: trees/<BRANCH_NAME>
   Branch: <BRANCH_NAME>
   Status: ❌ REMOVED

🗑️  Cleanup:
   ✓ Git worktree removed
   ✓ Git branch deleted
   ✓ Directory removed from trees/

📝 Important Notes:
   • Both the worktree AND branch '<BRANCH_NAME>' have been deleted
   • This removal is PERMANENT and cannot be undone
   • If you need this branch again, create a new one with:
     /create_worktree <BRANCH_NAME>
   • The new branch will start from your current HEAD

🔍 Verification:
   ✓ Worktree not in git worktree list
   ✓ Branch not in git branch list
   ✓ Directory trees/<BRANCH_NAME> removed

💡 View remaining worktrees:
   /list_worktrees
```

If any issues occurred during removal, include a warnings section:

```
⚠️  Warnings / Issues:
- Used --force flag to remove worktree (had uncommitted changes)
- Used -D flag to force delete branch (had unmerged changes)
```

If worktree was already partially removed or not found:

```
⚠️  Worktree Status:
- Worktree 'trees/<BRANCH_NAME>' was not found in git worktree list
- Directory may have been manually deleted
- Run 'git worktree prune' to clean up worktree metadata

📝 Cleanup Command:
   git worktree prune
```

If orphaned directory exists after removal:

```
⚠️  Manual Cleanup Required:
- Directory trees/<BRANCH_NAME> still exists after git worktree remove
- This should not happen normally
- To manually remove, run from PROJECT_CWD:
   rm -rf trees/<BRANCH_NAME>
```

If worktree doesn't exist:

```
❌ Worktree Not Found

⚠️  No worktree found for branch '<BRANCH_NAME>'

Check existing worktrees:
└─ /list_worktrees

Available worktrees:
[List of actual worktrees if any exist]

Did you mean:
[Suggest similar branch names if any]
```

If branch has uncommitted changes warning:

```
⚠️  Uncommitted Changes Detected

The worktree 'trees/<BRANCH_NAME>' has uncommitted changes.

Options:
1. Commit your changes first:
   cd trees/<BRANCH_NAME>
   git add .
   git commit -m "Save work"
   cd ../..
   /remove_worktree <BRANCH_NAME>

2. Force remove (LOSES uncommitted changes):
   This command will use --force to remove anyway

Proceed with force removal? This will PERMANENTLY DELETE uncommitted work.
```
