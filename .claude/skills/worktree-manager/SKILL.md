# Worktree Manager Skill

## Purpose
Create, remove, list, or manage worktrees with isolated ports, databases, and configuration.

## When to Use This Skill
Use this skill when the user wants to:
- Create a new worktree for parallel development
- Remove/delete an existing worktree
- List/view all current worktrees and their status
- Check worktree configuration or service status
- Set up isolated development environments

## When NOT to Use This Skill
Do NOT use this skill when:
- User asks for a specific subagent or skill delegation
- User wants to manually use git commands directly
- Task is unrelated to worktree management

## Critical Guidelines
1. **Always use slash commands** - Never manually create/remove worktrees
   - Commands handle all configuration automatically
   - Ensure port uniqueness
   - Validate operations
   - Provide comprehensive error handling

2. **Understand the context** - Know what the user is trying to achieve
   - Creating parallel development environments
   - Testing multiple features simultaneously
   - Reviewing PRs while working on other code

3. **Provide clear information** - Always share access details after operations
   - Dashboard URLs
   - Port assignments
   - Service status
   - Next steps

## Available Operations

### Create Worktree
**Command:** `/create_worktree <branch-name> [port-offset]`

**When to use:**
- User mentions "create", "new", "setup", or "make" a worktree
- User wants parallel development environment
- User needs to test multiple branches simultaneously

**What happens:**
- Creates new worktree in `trees/<branch-name>/`
- Assigns unique ports (auto-calculated or custom offset)
- Installs dependencies
- Starts services (server + client)
- Provides access URLs

**Your response should include:**
- Confirmation of creation
- Access URLs (Dashboard, Server, Client)
- Port assignments
- Instructions for accessing the environment

### List Worktrees
**Command:** `/list_worktrees`

**When to use:**
- User asks "what worktrees", "show worktrees", "list environments"
- User wants to see status of existing worktrees
- User needs to know which ports are in use
- Troubleshooting worktree issues

**What happens:**
- Shows all existing worktrees
- Displays service status (running/stopped)
- Shows port assignments
- Provides access URLs
- Lists process IDs

**Your response should include:**
- Clear summary of active worktrees
- Highlighted access information
- Status of services
- Any issues detected

### Remove Worktree
**Command:** `/remove_worktree <branch-name>`

**When to use:**
- User mentions "remove", "delete", "cleanup", "destroy" a worktree
- User is done with parallel development
- User wants to free up ports/resources
- Worktree is no longer needed

**What happens:**
- Stops all running services
- Removes worktree directory
- Cleans up configuration
- Frees ports
- Confirms removal

**Your response should include:**
- Confirmation of removal
- What was cleaned up
- Freed resources (ports)

## Example Workflows

### Example 1: User wants to create a worktree
**User:** "Create a worktree for feature-auth"

**Your action:**
```
1. Use SlashCommand tool: `/create_worktree feature-auth`
2. Wait for output
3. Share access URLs with user
```

**Your response:**
> I've created a new worktree for the `feature-auth` branch. Here's how to access it:
> - Dashboard: http://localhost:5183/dashboard
> - Server: http://localhost:4010
> - Client: http://localhost:5183
>
> Services are running and ready for development!

### Example 2: User wants to see their worktrees
**User:** "What worktrees do I have?"

**Your action:**
```
1. Use SlashCommand tool: `/list_worktrees`
2. Parse the output
3. Summarize for user
```

**Your response:**
> Here are your current worktrees:
>
> 1. **feature-auth** (Offset 1)
>    - Server: http://localhost:4010 (Running, PID: 12345)
>    - Client: http://localhost:5183 (Running, PID: 12346)
>    - Dashboard: http://localhost:5183/dashboard
>
> 2. **hotfix-bug** (Offset 2)
>    - Server: http://localhost:4020 (Stopped)
>    - Client: http://localhost:5193 (Stopped)

### Example 3: User wants to remove a worktree
**User:** "Delete the feature-auth worktree"

**Your action:**
```
1. Use SlashCommand tool: `/remove_worktree feature-auth`
2. Wait for confirmation
3. Inform user
```

**Your response:**
> Successfully removed the `feature-auth` worktree:
> - Stopped all running services
> - Cleaned up directories
> - Freed ports 4010 and 5183

## Key Concepts

### Port Allocation
- Main repo: Server=4000, Client=5173
- Worktree offset N: Server=4000+(N*10), Client=5173+(N*10)
- Auto-calculated: Finds highest existing offset and increments

### Isolation
Each worktree has:
- Own working directory (`trees/<branch>/`)
- Unique ports
- Isolated configuration (`.env`, `.claude/settings.json`)
- Separate services
- Independent dependencies

### Service Management
Each worktree runs:
- Server process (backend API)
- Client process (frontend dev server)

Both run as background processes with tracked PIDs.

## Troubleshooting Reference

Common issues and quick solutions:

1. **Port conflicts** - Use explicit port offset when creating
2. **Services won't start** - Check if ports are already in use
3. **Can't access worktree** - Run `/list_worktrees` to see URLs
4. **Worktree creation fails** - Check if worktree already exists for that branch
5. **Services won't stop** - Use `/remove_worktree` which force-kills processes

## Important Reminders

- ✓ Always use slash commands, never manual git worktree commands
- ✓ Provide access URLs after creating worktrees
- ✓ Check existing worktrees before creating new ones
- ✓ Clean up unused worktrees to free resources
- ✓ Explain port allocation to users when relevant

## Documentation Files

For detailed information, refer to:
- **OPERATIONS.md** - Step-by-step operational procedures
- **EXAMPLES.md** - Real-world usage scenarios and pattern recognition
- **TROUBLESHOOTING.md** - Common issues and solutions
- **REFERENCE.md** - Technical specifications and command syntax
