#!/usr/bin/env bash
#
# vercel-deploy.sh — deploy ./_site to Vercel (used by the Drafts workflow).
# Bootstraps the project on first run if it does not exist yet (idempotent).
#
# Usage: .github/scripts/vercel-deploy.sh [--prod]
#   (no flag  → preview deployment, random URL)
#   (--prod   → production deployment, stable <project>.vercel.app URL)
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."   # repo root
TARGET="_site"

: "${VERCEL_TOKEN:?VERCEL_TOKEN secret is not set on this repository}"
: "${VERCEL_ORG_ID:?VERCEL_ORG_ID is not set (should come from the workflow env)}"
: "${VERCEL_PROJECT_NAME:?VERCEL_PROJECT_NAME is not set (should come from the workflow env)}"
API="https://api.vercel.com"

# ------------------------------------------------- ensure the project exists
PROJECT_ID="$(
  curl -fsSL "$API/v10/projects?teamId=${VERCEL_ORG_ID}" \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    | jq -r --arg n "${VERCEL_PROJECT_NAME}" '.projects[] | select(.name==$n) | .id' || true
)"

if [ -z "${PROJECT_ID:-}" ]; then
  echo "==> Creating Vercel project '${VERCEL_PROJECT_NAME}'"
  PROJECT_ID="$(
    curl -fsSL "$API/v11/projects?teamId=${VERCEL_ORG_ID}" \
      -H "Authorization: Bearer ${VERCEL_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"${VERCEL_PROJECT_NAME}\"}" \
    | jq -r '.project.id'
  )"
fi
echo "==> Project: ${PROJECT_ID}"

# --------------------------------------------------------------------- deploy
npm install -g vercel@latest --silent

ARGS=(deploy "$TARGET" --yes --project "$PROJECT_ID")
[ "${1:-}" = "--prod" ] && ARGS+=(--prod)
vercel "${ARGS[@]}"
