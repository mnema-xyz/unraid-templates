#!/bin/bash
# Consistent backup of a Mnema Talk install from the Community Apps templates
# (three containers: Talk, PostgreSQL 18, SeaweedFS-Mnema). Run it as root on
# the Unraid server, for example nightly from the User Scripts plugin:
#
#   BACKUP_DIR=/mnt/user/backups/mnema-talk bash /path/to/mnema-talk-backup.sh
#
# It stops Talk and SeaweedFS for a few seconds (active calls disconnect),
# dumps the database with pg_dump, archives the SeaweedFS appdata folder and
# copies the three Docker templates (they hold your secrets), then starts both
# again. Afterwards it imports the dump into a throwaway PostgreSQL container
# without network as a restore test, writes the result for Admin > Status
# when the Talk container mounts /backup-status, and removes complete backups
# older than KEEP_DAYS. A failed restore test keeps every older backup.
#
# Settings (environment):
#   BACKUP_DIR      where backups go (required; never inside appdata)
#   KEEP_DAYS       days to keep complete backups (default 14)
#   RESTORE_TEST    1 (default) or 0
#   TALK_CONTAINER  default Mnema-Talk
#   PG_CONTAINER    default postgresql18
#   S3_CONTAINER    default SeaweedFS-Mnema
set -euo pipefail
umask 077
fail() { echo "backup: $*" >&2; exit 1; }

BACKUP_DIR=${BACKUP_DIR:?set BACKUP_DIR, for example /mnt/user/backups/mnema-talk}
KEEP_DAYS=${KEEP_DAYS:-14}
RESTORE_TEST=${RESTORE_TEST:-1}
TALK=${TALK_CONTAINER:-Mnema-Talk}
PG=${PG_CONTAINER:-postgresql18}
S3=${S3_CONTAINER:-SeaweedFS-Mnema}
TEMPLATES=/boot/config/plugins/dockerMan/templates-user
# Pinned like the images the Talk repository uses for its own backups.
ALPINE=alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
[[ "$KEEP_DAYS" =~ ^[0-9]+$ ]] || fail 'KEEP_DAYS must be a whole number'
[[ "$RESTORE_TEST" =~ ^[01]$ ]] || fail 'RESTORE_TEST must be 1 or 0'

running() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = true ]; }
mount_of() { docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$2\"}}{{.Source}}{{end}}{{end}}" "$1"; }
env_of() { docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$1" | sed -n "s/^$2=//p"; }
wait_up() {
  local state
  for _ in $(seq 1 180); do
    state=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Running}}{{end}}' "$1")
    case "$state" in healthy|true) return 0 ;; esac
    sleep 1
  done
  return 1
}

for c in "$TALK" "$PG" "$S3"; do docker inspect "$c" >/dev/null 2>&1 || fail "no container named $c (set TALK_CONTAINER, PG_CONTAINER, S3_CONTAINER)"; done
running "$PG" || fail "$PG must be running"
S3_DATA=$(mount_of "$S3" /data)
[ -n "$S3_DATA" ] && [ -d "$S3_DATA" ] || fail "$S3 has no /data folder"
STATUS_DIR=$(mount_of "$TALK" /backup-status)
PG_VERSION=$(docker exec "$PG" sh -c 'echo "$PG_MAJOR"')
[ -n "$PG_VERSION" ] || fail "$PG is not an official postgres image"

mkdir -p "$BACKUP_DIR"
lock="$BACKUP_DIR/.lock"
mkdir "$lock" 2>/dev/null || fail "another backup holds $lock; remove it only if no backup runs"
talk_resume=false s3_resume=false dest='' complete=false
cleanup() {
  local status=$?
  trap - EXIT
  if [ "$s3_resume" = true ] && ! { docker start "$S3" >/dev/null && wait_up "$S3"; }; then
    status=1 talk_resume=false
    echo "backup: $S3 did not start again; $TALK stays stopped" >&2
  fi
  if [ "$talk_resume" = true ] && ! { docker start "$TALK" >/dev/null && wait_up "$TALK"; }; then
    status=1
    echo "backup: $TALK did not become healthy" >&2
  fi
  rmdir "$lock"
  [ "$status" = 0 ] || [ "$complete" = true ] || { echo 'backup failed; an incomplete folder is no restore point' >&2; [ -z "$dest" ] || touch "$dest/FAILED"; }
  exit "$status"
}
trap cleanup EXIT

ts=$(date -u +%Y%m%d-%H%M%S)
dest=$(mktemp -d "$BACKUP_DIR/$ts-XXXXXX")
echo "backup $ts: stopping $TALK and $S3 (active calls disconnect)"
if running "$TALK"; then talk_resume=true; docker stop -t 60 "$TALK" >/dev/null; fi
if running "$S3"; then s3_resume=true; docker stop -t 60 "$S3" >/dev/null; fi
docker exec "$PG" sh -c 'pg_dump -U "$POSTGRES_USER" -d "${POSTGRES_DB:-$POSTGRES_USER}" --no-owner' </dev/null | gzip > "$dest/postgres.sql.gz"
docker exec "$PG" sh -c 'psql -U "$POSTGRES_USER" -d "${POSTGRES_DB:-$POSTGRES_USER}" -At -v ON_ERROR_STOP=1 -c "SELECT filename, checksum FROM schema_migrations ORDER BY filename"' </dev/null > "$dest/schema.txt"
# Regular files and folders only, so a restore cannot be steered outside /data.
docker run --rm --network none -v "$S3_DATA":/data:ro -v "$dest":/out "$ALPINE" sh -c '
  bad=$(find /data ! -type f ! -type d | head -n 1)
  [ -z "$bad" ] || { echo "unexpected special file in the media folder: $bad" >&2; exit 1; }
  tar czf /out/seaweedfs.tar.gz -C /data . && chmod 600 /out/seaweedfs.tar.gz'
mkdir "$dest/templates"
for c in "$TALK" "$PG" "$S3"; do cp "$TEMPLATES/my-$c.xml" "$dest/templates/" 2>/dev/null || echo "backup: no template my-$c.xml (container not made from the Docker tab?)" >&2; done
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
{
  echo format=mnema-unraid-backup-v1
  echo "created_utc=$created"
  for c in "$TALK" "$PG" "$S3"; do echo "image_$c=$(docker inspect -f '{{.Config.Image}} {{.Image}}' "$c")"; done
  echo "postgres_major=$PG_VERSION"
} > "$dest/manifest"
sums=$(cd "$dest" && find . -type f -print0 | sort -z | xargs -0 sha256sum)
printf '%s\n' "$sums" > "$dest/SHA256SUMS"
gzip -t "$dest/postgres.sql.gz" && gzip -t "$dest/seaweedfs.tar.gz"
echo mnema-unraid-backup-v1 > "$dest/COMPLETE"
complete=true
# Services back first; the restore test below does not need them stopped.
if [ "$s3_resume" = true ]; then docker start "$S3" >/dev/null; wait_up "$S3" || fail "$S3 did not start again"; s3_resume=false; fi
if [ "$talk_resume" = true ]; then docker start "$TALK" >/dev/null; wait_up "$TALK" || fail "$TALK did not become healthy"; talk_resume=false; fi

result=skipped tested_at=''
if [ "$RESTORE_TEST" = 1 ]; then
  check=$(docker run --rm -d --network none -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=verify "postgres:$PG_VERSION")
  ok=false
  for _ in $(seq 1 60); do
    if docker exec "$check" sh -c '[ "$(cat /proc/1/comm)" = postgres ] && pg_isready -U postgres -d verify' >/dev/null 2>&1; then ok=true; break; fi
    sleep 1
  done
  if [ "$ok" = true ] && gunzip -c "$dest/postgres.sql.gz" | docker exec -i "$check" psql -U postgres -d verify -v ON_ERROR_STOP=1 -q >/dev/null \
     && docker exec "$check" psql -U postgres -d verify -At -v ON_ERROR_STOP=1 -c "SELECT 'users ' || count(*) FROM users UNION ALL SELECT 'messages ' || count(*) FROM messages UNION ALL SELECT 'migrations ' || count(*) FROM schema_migrations"; then
    result=passed
  else
    result=failed
  fi
  docker rm -f -v "$check" >/dev/null
  tested_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
fi

# Admin > Status reads this file (BACKUP_STATUS_FILE=/backup-status/status.json).
if [ -n "$STATUS_DIR" ]; then
  size=$(du -sb "$dest" | cut -f1)
  tmp=$(mktemp "$STATUS_DIR/.status.XXXXXX")
  printf '{"format":1,"last_backup_at":"%s","size_bytes":%s,"restore_test":{"result":"%s"%s}}\n' \
    "$created" "$size" "$result" "${tested_at:+,\"at\":\"$tested_at\"}" > "$tmp"
  chmod 644 "$tmp" && mv -f "$tmp" "$STATUS_DIR/status.json"
fi

if [ "$result" != failed ]; then
  find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -name '20*' -mtime +"$KEEP_DAYS" -print0 |
    while IFS= read -r -d '' old; do
      if [ "$old" != "$dest" ] && [ -f "$old/COMPLETE" ] && [ ! -e "$old/FAILED" ]; then rm -rf -- "$old"; fi
    done
fi
echo "backup complete: $dest (restore test: $result)"
[ "$result" != failed ] || fail 'restore test FAILED: this backup may not be restorable; older backups were kept'
