#!/usr/bin/env bash
set -euo pipefail

# Inputs: TOKEN, REPO (optional)
source "$(dirname "$0")/common.sh"

REPO="${REPO:-${GITHUB_REPOSITORY}}"

# Token usable?
api_get "https://api.github.com/rate_limit" > /dev/null

# Repo visible to the installation?
api_get "https://api.github.com/repos/${REPO}" > /dev/null
