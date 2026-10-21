#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

readonly STACK_DB_CONTAINER="supabase_db_tryzeon-app"
readonly COMPOSE_FILE="scripts/local-backend/compose.yaml"
readonly FUNCTIONS_ENV="supabase/functions/.env"
readonly S3_BUCKETS=(tryzeon-public-images tryzeon-tryon-images tryzeon-tryon-videos)
readonly VOLUMES=(
  supabase_db_tryzeon-app
  supabase_storage_tryzeon-app
  tryzeon-app-dev_seaweedfs-data
  tryzeon-app-dev_redis-data
)
readonly SNAPSHOT_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/tryzeon-app/snapshots"

usage() {
  cat >&2 <<'EOF'
Usage: scripts/local-backend.sh <command>

  up               Start Supabase, SeaweedFS (R2) and Redis (Upstash) for local dev
  down             Stop everything, keeping all data
  status           Show what is running, migration drift against main, and snapshots
  snapshot <name>  Save the database and every stored file under <name>
  restore <name>   Replace the current data with snapshot <name>
EOF
  exit 1
}

die() {
  echo "error: $*" >&2
  exit 1
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

weed_shell() {
  echo "$1" | compose exec -T seaweedfs weed shell 2>&1
}

ensure_buckets() {
  local existing
  existing=$(weed_shell "s3.bucket.list")
  for bucket in "${S3_BUCKETS[@]}"; do
    if ! grep -qE "^\s*${bucket}\s" <<<"$existing"; then
      weed_shell "s3.bucket.create -name $bucket" | tail -1
    fi
  done
}

preflight() {
  [[ -r "$FUNCTIONS_ENV" ]] ||
    die "$PWD/$FUNCTIONS_ENV is missing or unreadable; create it in the main checkout from supabase/functions/.env.example"

  local others
  others=$(docker ps --format '{{.Names}}' | grep -E '^supabase_db_' | grep -vx "$STACK_DB_CONTAINER" || true)
  [[ -z "$others" ]] ||
    die "another Supabase stack holds the local ports; stop it first (supabase stop in its worktree):"$'\n'"$others"
}

cmd_up() {
  preflight
  supabase start
  compose up -d --wait
  ensure_buckets

  cat <<'EOF'

Local backend is up.
  Studio     http://127.0.0.1:54323
  Mailpit    http://127.0.0.1:54324
  SeaweedFS  http://127.0.0.1:8333
  Redis REST http://127.0.0.1:8079

Edge functions are served from this worktree. To test another worktree's
functions, run `supabase functions serve` there; stopping it takes them down
until the next `up` or `serve`.

Next: `flutter run --dart-define=APP_ENV=local`.
EOF
}

cmd_down() {
  supabase stop
  compose stop
}

applied_migrations() {
  docker exec "$STACK_DB_CONTAINER" psql -U postgres -Atc \
    "select version from supabase_migrations.schema_migrations order by version"
}

main_migrations() {
  git ls-tree --name-only main supabase/migrations/ | sed -E 's#.*/([0-9]+)_.*#\1#' | sort
}

cmd_status() {
  if ! docker ps --format '{{.Names}}' | grep -qx "$STACK_DB_CONTAINER"; then
    echo "Local backend: stopped"
  else
    echo "Local backend: running"
    local applied expected
    applied=$(applied_migrations)
    expected=$(main_migrations)
    local extra pending
    extra=$(comm -23 <(echo "$applied") <(echo "$expected"))
    pending=$(comm -13 <(echo "$applied") <(echo "$expected"))
    echo "Applied but not on main:"
    sed 's/^/  /' <<<"${extra:-none}"
    echo "On main but not applied:"
    sed 's/^/  /' <<<"${pending:-none}"
  fi

  echo "Snapshots:"
  if [[ -d "$SNAPSHOT_ROOT" ]] && [[ -n "$(ls -A "$SNAPSHOT_ROOT")" ]]; then
    ls -1 "$SNAPSHOT_ROOT" | { grep -v '\.partial$' || true; } | sed 's/^/  /'
  else
    echo "  none"
  fi
}

snapshot_dir() {
  local name="${1:-}"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "snapshot name must match [A-Za-z0-9._-]+"
  echo "$SNAPSHOT_ROOT/$name"
}

cmd_snapshot() {
  local dir
  dir=$(snapshot_dir "${1:-}")
  [[ ! -e "$dir" ]] || die "snapshot '$1' already exists at $dir"
  preflight

  local partial="$dir.partial"
  rm -rf "$partial"
  mkdir -p "$partial"
  trap "rm -rf '$partial'" EXIT

  cmd_down
  for volume in "${VOLUMES[@]}"; do
    if ! docker run --rm -v "$volume":/v:ro -v "$partial":/b alpine:3.22 tar -C /v -czf "/b/$volume.tgz" .; then
      cmd_up
      die "failed to archive $volume; snapshot '$1' discarded"
    fi
  done
  mv "$partial" "$dir"
  trap - EXIT
  cmd_up
  echo "Saved snapshot '$1' to $dir"
}

cmd_restore() {
  local dir
  dir=$(snapshot_dir "${1:-}")
  [[ -d "$dir" ]] || die "snapshot '$1' does not exist"
  for volume in "${VOLUMES[@]}"; do
    [[ -f "$dir/$volume.tgz" ]] || die "snapshot '$1' is incomplete: $volume.tgz is missing"
    gzip -t "$dir/$volume.tgz" 2>/dev/null || die "snapshot '$1' is corrupt: $volume.tgz does not decompress"
  done
  preflight

  cmd_down
  for volume in "${VOLUMES[@]}"; do
    docker run --rm -v "$volume":/v -v "$dir":/b:ro alpine:3.22 \
      sh -c "find /v -mindepth 1 -delete && tar -C /v -xzf /b/$volume.tgz" ||
      die "failed to restore $volume; the backend is stopped, rerun restore '$1' to retry"
  done
  cmd_up
  echo "Restored snapshot '$1'"
}

case "${1:-}" in
  up) cmd_up ;;
  down) cmd_down ;;
  status) cmd_status ;;
  snapshot) cmd_snapshot "${2:-}" ;;
  restore) cmd_restore "${2:-}" ;;
  *) usage ;;
esac
