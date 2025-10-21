#!/usr/bin/env bash
set -euo pipefail
# Inputs: TOKEN REPO ACT NUM TITLE BODY BASE HEAD DRAFT ACTOR
source "$(dirname "$0")/common.sh"

REPO="${REPO:-${GITHUB_REPOSITORY}}"

# Normalize DRAFT to "true"/"false"
case "${DRAFT:-}" in true|false) : ;; *) DRAFT="false" ;; esac

PVT="$(provenance_block)"
# Convert literal \n to actual newlines in body
BODY_PROCESSED="$(printf '%b' "${BODY:-}")"
BODY_JOINED="$(printf '%s\n\n%s' "$BODY_PROCESSED" "$PVT")"

case "${ACT}" in
  open-issue)
    [[ -n "${TITLE:-}" ]] || { echo "Missing 'title' for open-issue" >&2; exit 1; }
    payload="$(jq -nc --arg title "$TITLE" --arg body "$BODY_JOINED" \
      '{title:$title, body:$body, labels:["ai"]}')"
    api_post "https://api.github.com/repos/${REPO}/issues" "${payload}" > /dev/null
    ;;

  pr-comment|issue-comment)
    [[ -n "${NUM:-}" ]] || { echo "Missing 'number' for ${ACT}" >&2; exit 1; }
    payload="$(jq -nc --arg b "$BODY_JOINED" '{body:$b}')"
    api_post "https://api.github.com/repos/${REPO}/issues/${NUM}/comments" "${payload}" > /dev/null
    ;;

  pr-code)
    [[ -n "${NUM:-}" ]] || { echo "Missing 'number' for pr-code" >&2; exit 1; }
    code_body="$(printf '%s\n\n```diff\n%s\n```' "$PVT" "${BODY:-}")"
    payload="$(jq -nc --arg b "$code_body" '{body:$b}')"
    api_post "https://api.github.com/repos/${REPO}/issues/${NUM}/comments" "${payload}" > /dev/null
    ;;

  open-pr)
    [[ -n "${TITLE:-}" ]] || { echo "Missing 'title' for open-pr" >&2; exit 1; }
    [[ -n "${BASE:-}"  ]] || { echo "Missing 'base' for open-pr"  >&2; exit 1; }
    [[ -n "${HEAD:-}"  ]] || { echo "Missing 'head' for open-pr"  >&2; exit 1; }
    payload="$(jq -nc \
      --arg title "$TITLE" --arg body "$BODY_JOINED" \
      --arg base "$BASE"  --arg head "$HEAD" \
      --argjson draft ${DRAFT:-false} \
      '{title:$title, body:$body, base:$base, head:$head, draft:$draft}')"
    api_post "https://api.github.com/repos/${REPO}/pulls" "${payload}" > /dev/null
    ;;

  *)
    echo "Unknown action: ${ACT}" >&2; exit 1 ;;
esac
