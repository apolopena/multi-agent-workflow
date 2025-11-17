# Worktree Operations Guide

## Overview

This guide provides instructions for managing git worktrees through three main operations: creating, listing, and removing worktrees.

## CREATE Operations

When establishing a new worktree:

1. **Gather Requirements**: Collect the branch name (mandatory) and optional port offset for custom configuration.

2. **Execute Creation**: Run `/create_worktree <branch-name> [port-offset]`

3. **Automatic Setup**: The system creates the worktree directory structure, assigns unique ports, generates environment configuration files, installs required dependencies, and launches background services.

4. **Provide Access Information**: Share the dashboard URL, assigned ports, service access details, and worktree directory location with the user.

## LIST Operations

To view existing worktrees:

1. **Query Worktrees**: Execute `/list_worktrees`

2. **Review Output**: The command displays all worktrees with their paths, port assignments, service status including process IDs, and corresponding access URLs.

3. **Communicate Results**: Inform the user which worktrees are currently active, how to access them, and alert them to any potential issues.

## REMOVE Operations

When deleting a worktree:

1. **Identify Target**: Determine which branch's worktree to remove.

2. **Execute Removal**: Run `/remove_worktree <branch-name>`

3. **Cleanup Process**: The system terminates services, releases ports, deletes the worktree, removes associated files, and verifies successful removal.

4. **Confirm Completion**: Report removal success, which services were halted, and cleanup activities performed.
