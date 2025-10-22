#!/usr/bin/env bash
# AI-aware git wrapper with keychain support
# Usage: ./scripts/git-ai.sh commit -m "message"
#        ./scripts/git-ai.sh push
#        ./scripts/git-ai.sh pull

set -euo pipefail

# Load non-sensitive environment variables (warn but continue)
if [ -f env/.env ]; then
  source env/.env
fi

# Load SSH keychain (REQUIRED - fail if missing)
KEYCHAIN_FILE="$HOME/.keychain/$(hostname)-sh"
if [ -f "$KEYCHAIN_FILE" ]; then
  source "$KEYCHAIN_FILE"
else
  echo "Error: Keychain file not found at $KEYCHAIN_FILE" >&2
  echo "Please set up keychain for SSH agent management." >&2
  echo "See: https://www.funtoo.org/Funtoo:Keychain" >&2
  exit 1
fi

# Check if command is 'commit' - add AI attribution
if [ "${1:-}" = "commit" ]; then
  GIT_USER=$(git config user.name)
  AI_ATTRIBUTION="${GIT_USER} · AI: ${AI_AGENT_NAME:-}"
  shift  # Remove 'commit' from args
  git -c user.name="$AI_ATTRIBUTION" commit "$@"
else
  # For other commands (push, pull, fetch, etc.), just run git normally
  git "$@"
fi
