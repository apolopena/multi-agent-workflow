# Worktree Quick Reference - Complete Contents

## Command Syntax

### Create Worktree
```bash
/create_worktree <branch-name> [port-offset]
```

**Parameters:**
- `branch-name` (required) - Name of the git branch
- `port-offset` (optional) - Port offset number (default: auto-calculated)

**Examples:**
```bash
/create_worktree feature-auth
/create_worktree hotfix-bug 3
```

### List Worktrees
```bash
/list_worktrees
```

No parameters required. Output displays worktree paths, port settings, service statuses with process IDs, access URLs, and available commands.

### Remove Worktree
```bash
/remove_worktree <branch-name>
```

**Parameters:**
- `branch-name` (required) - Name of the worktree to remove

**Example:**
```bash
/remove_worktree feature-auth
```

## Port Allocation

### Calculation Formula
```
SERVER_PORT = 4000 + (offset * 10)
CLIENT_PORT = 5173 + (offset * 10)
```

| Environment | Offset | Server Port | Client Port |
|-------------|--------|-------------|-------------|
| Main Repo   | 0      | 4000        | 5173        |
| Worktree 1  | 1      | 4010        | 5183        |
| Worktree 2  | 2      | 4020        | 5193        |
| Worktree 3  | 3      | 4030        | 5203        |
| Worktree 4  | 4      | 4040        | 5213        |
| Worktree 5  | 5      | 4050        | 5223        |

Auto-calculated offsets identify the highest existing offset, increment it by one, and apply that value automatically.

## Directory Structure

### Main Repository
```
project/
├── .claude/
│   ├── settings.json
│   └── commands/
├── .env
├── server/
└── client/
```

### Worktree Structure
```
project/
└── trees/
    └── <branch-name>/
        ├── .claude/
        │   └── settings.json (isolated config)
        ├── .env (unique ports)
        ├── server/
        └── client/
```

## Configuration Files

### .env (Worktree-specific)
```env
VITE_SERVER_URL=http://localhost:[SERVER_PORT]
VITE_CLIENT_PORT=[CLIENT_PORT]
SERVER_PORT=[SERVER_PORT]
```

### .claude/settings.json (Worktree-specific)
```json
{
  "hooks": {
    "userPromptSubmit": {
      "script": "...",
      "env": {
        "AGENT_SERVER_URL": "http://localhost:[SERVER_PORT]"
      }
    }
  }
}
```

## Service Management

Each worktree runs two services:
1. **Server** - Backend API (Express/Node)
2. **Client** - Frontend dev server (Vite)

Services operate as detached background processes with tracked PIDs. The system automatically manages cleanup upon removal and force-terminates unresponsive processes.

**Service States:**
- Running: Active process with valid PID
- Stopped: No active process
- Zombie: PID exists but process unresponsive

## Git Worktree Fundamentals

A git worktree provides an additional working directory linked to the same repository. Multiple worktrees can coexist, each on different branches, enabling simultaneous work without constant branch switching.

**Benefits:**
- Parallel work across multiple branches
- Eliminate stash/switch workflows
- Isolated development environments
- Concurrent feature testing

**Limitations:**
- Each branch exists in only one worktree
- Worktrees share git history and objects
- Each requires disk space

## Isolation Features

| Feature | Level | Details |
|---------|-------|---------|
| **File System** | Complete | Separate working directory |
| **Ports** | Complete | Unique allocation |
| **Configuration** | Complete | Own .env and settings.json |
| **Database** | Configurable | Separate DBs possible |
| **Dependencies** | Complete | Own node_modules |
| **Git History** | Shared | Same repository |
| **Git Config** | Shared | Same git settings |

## Best Practices

### Appropriate Use Cases
✓ Testing multiple features simultaneously
✓ Reviewing PRs during active development
✓ Hot-fixing production while continuing feature work
✓ Isolated integration test execution

### Inappropriate Use Cases
✗ Simple branch switching (use git checkout)
✗ Temporary file viewing (use git show)
✗ Quick edits (stash and switch)

### Maintenance Guidelines
- Remove worktrees after feature merging
- Prevent accumulation of unused worktrees
- Regularly audit with `/list_worktrees`
- Preserve ports for active development

### Naming Standards
- Use descriptive, clear names
- Exclude special characters
- Keep names brief and memorable
- Align with existing branch naming conventions

## Technical Implementation

### Creation Workflow
1. Validate branch existence
2. Calculate/verify port offset
3. Create git worktree
4. Copy configuration templates
5. Update port values in configs
6. Install dependencies
7. Start services
8. Verify successful startup
9. Display access information

### Removal Workflow
1. Identify processes on worktree ports
2. Terminate server process
3. Terminate client process
4. Remove git worktree
5. Clean up directories
6. Confirm removal
7. Report completion

### Status Verification
1. List git worktrees
2. Read configuration for each
3. Verify running processes
4. Check port accessibility
5. Generate detailed report
