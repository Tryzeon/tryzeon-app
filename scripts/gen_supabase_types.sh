#!/usr/bin/env bash
# Regenerate the edge functions' schema types from the local Supabase stack.
#
# Run after any migration that adds or changes a type, table, or column, and
# commit the result — `vocabularies.ts` re-exports its runtime arrays straight
# from this file's generated `Constants` object, so a stale copy means stale
# vocabularies reach the model, and can mean the module imports values that no
# longer exist. Never edit the output by hand.
#
# Reads the local stack, not the hosted project: the local one is the migrations
# in this repo, which is what the committed types should describe. The stack is
# shared by every worktree, so it refuses to run unless the applied migrations
# are exactly this worktree's.
set -euo pipefail

cd "$(dirname "$0")/.."

readonly TYPES_FILE="supabase/functions/_shared/database.types.ts"

if ! supabase status >/dev/null 2>&1; then
  echo "Local Supabase stack is not running. Start it with: supabase db start" >&2
  exit 1
fi

drift=$(supabase migration list --local --output-format json |
  jq -r '.migrations[] | select(.local != .remote) |
    if (.local // "") == "" then "  applied but not in this worktree: \(.remote)"
    else "  in this worktree but not applied: \(.local)" end')
if [[ -n "$drift" ]]; then
  echo "Local database migrations differ from supabase/migrations:" >&2
  echo "$drift" >&2
  echo "Run \`supabase migration up --local\`, or restore a snapshot without the extra ones." >&2
  exit 1
fi

supabase gen types typescript --local > "$TYPES_FILE"
deno fmt --config supabase/functions/deno.json --quiet "$TYPES_FILE"
echo "Wrote $TYPES_FILE"
