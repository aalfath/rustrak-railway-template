#!/busybox/busybox sh
# Start script for Rustrak on Railway. Every failure exits non-zero, so
# Railway's ON_FAILURE restart policy brings the service back.
set -eu
bb=/busybox/busybox

log() { echo "[railway-start] $*"; }
fail() { echo "[railway-start] ERROR: $*" >&2; exit 1; }

# Settings that suit Railway; each can still be overridden with a variable.
export HOST="${HOST:-::}"
export PORT="${PORT:-8080}"
export SSL_PROXY="${SSL_PROXY:-true}"
export RUSTRAK_TELEMETRY="${RUSTRAK_TELEMETRY:-off}"
# Upstream keeps accepted-but-not-yet-stored events in /tmp, which a restart
# empties. Keep them on the volume instead.
export INGEST_DIR="${INGEST_DIR:-/data/ingest}"
export SOURCEMAP_STORAGE_PATH="${SOURCEMAP_STORAGE_PATH:-/data/sourcemaps}"

[ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL is not set (it should reference the Postgres service)."
key="${SESSION_SECRET_KEY:-}"
[ "${#key}" -ge 64 ] || fail "SESSION_SECRET_KEY must be at least 64 characters."
[ -n "${PUBLIC_URL:-}" ] || log "PUBLIC_URL is not set: DSNs will show the bind address."

# The first admin, created by Rustrak only while the database has no users.
if [ -z "${CREATE_SUPERUSER:-}" ] && [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
  export CREATE_SUPERUSER="${ADMIN_EMAIL}:${ADMIN_PASSWORD}"
fi
unset ADMIN_PASSWORD

# Wait for PostgreSQL (up to 3 minutes) so a first deploy never races it.
rest="${DATABASE_URL#*://}"
rest="${rest##*@}"
hostport="${rest%%/*}"
hostport="${hostport%%\?*}"
case "$hostport" in
  \[*\]:*) dbhost="${hostport%%]:*}"; dbhost="${dbhost#[}"; dbport="${hostport##*]:}" ;;
  \[*\])   dbhost="${hostport#[}"; dbhost="${dbhost%]}"; dbport=5432 ;;
  *:*)     dbhost="${hostport%:*}"; dbport="${hostport##*:}" ;;
  *)       dbhost="$hostport"; dbport=5432 ;;
esac
log "waiting for PostgreSQL at ${dbhost}:${dbport}"
i=0
until $bb nc -z -w 3 "$dbhost" "$dbport" >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -lt 60 ] || fail "PostgreSQL at ${dbhost}:${dbport} did not answer within 3 minutes."
  $bb sleep 3
done

# The Railway volume is mounted at /data and owned by root.
$bb mkdir -p /data "$INGEST_DIR" "$SOURCEMAP_STORAGE_PATH"
for d in /data "$INGEST_DIR" "$SOURCEMAP_STORAGE_PATH"; do
  if [ "$($bb stat -c %u "$d")" != "65532" ]; then
    $bb chown -R 65532:65532 "$d"
  fi
done

log "starting Rustrak (PostgreSQL build) on ${HOST} port ${PORT}"
# Rustrak exits 0 after a graceful stop, and Railway's ON_FAILURE policy does
# not restart a service that exits 0. So run it as a child, pass a stop signal
# on, and always exit non-zero, letting Railway bring the service back after
# any stop it did not ask for itself.
$bb setuidgid nonroot /app/rustrak &
child=$!
sig=""
# Background jobs of a non-interactive shell ignore SIGINT, and Rustrak treats
# SIGTERM and SIGINT alike, so both are passed on as SIGTERM.
trap 'sig=TERM; $bb kill -TERM "$child" 2>/dev/null || true' TERM
trap 'sig=INT; $bb kill -TERM "$child" 2>/dev/null || true' INT
while :; do
  code=0
  wait "$child" || code=$?
  $bb kill -0 "$child" 2>/dev/null || break
done
if [ -n "$sig" ]; then
  log "stopped by SIG${sig} (Rustrak exit code ${code})"
  if [ "$code" -eq 0 ]; then
    if [ "$sig" = TERM ]; then code=143; else code=130; fi
  fi
elif [ "$code" -eq 0 ]; then
  log "Rustrak exited without being asked to stop; exiting 1 so Railway restarts it"
  code=1
else
  log "Rustrak exited with code ${code}"
fi
exit "$code"
