#!/bin/bash
# Untrack .ai/scratch/ files that were committed before .gitignore rule

git rm --cached .ai/scratch/PLANNING.md
git rm --cached .ai/scratch/arch-primer.md
git rm --cached .ai/scratch/catalytic-customer-spec-v1.md
git rm --cached .ai/scratch/ce-port-session-summary.md
git rm --cached .ai/scratch/context-primer.md
git rm --cached .ai/scratch/prime-optimization-todo.md
git rm --cached .ai/scratch/docs/deployment-hardening.md
git rm --cached .ai/scratch/docs/email-setup-guide.md
git rm --cached .ai/scratch/docs/websocket-implementation.md

echo "Files untracked. They remain on disk but will no longer be tracked by git."
echo "Run 'git status' to verify."
