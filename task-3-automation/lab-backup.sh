#!/usr/bin/env bash
# lab-backup.sh: archive logs, prune old archives, notify a webhook
set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/lab-backup/lab-backup.env}"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

SOURCE_DIR="${SOURCE_DIR:-/var/log/nginx}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/lab}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
WEBHOOK_TOKEN="${WEBHOOK_TOKEN:-}"

stamp="$(date +%Y%m%d-%H%M%S)"
archive="$BACKUP_DIR/logs-$(hostname)-$stamp.tar.gz"

log() { echo "$(date '+%F %T') [lab-backup] $*"; }

notify() {
  [[ -z "$WEBHOOK_URL" ]] && return 0
  curl -fsS -m 10 -X POST \
    -H "Content-Type: application/json" \
    -H "X-Backup-Token: $WEBHOOK_TOKEN" \
    -d "{\"host\":\"$(hostname)\",\"status\":\"$1\",\"message\":\"$2\"}" \
    "$WEBHOOK_URL" >/dev/null || log "webhook call failed"
}

trap 'notify failure "backup failed at line $LINENO"' ERR

mkdir -p "$BACKUP_DIR"
exec 9>"$BACKUP_DIR/.lock"
flock -n 9 || { log "another run is active, exiting"; exit 0; }

log "archiving $SOURCE_DIR -> $archive"
tar -czf "$archive" --warning=no-file-changed "$SOURCE_DIR" 2>/dev/null || [[ $? -eq 1 ]]
tar -tzf "$archive" >/dev/null          # verify the archive opens

size="$(du -h "$archive" | cut -f1)"
find "$BACKUP_DIR" -name 'logs-*.tar.gz' -mtime +"$RETENTION_DAYS" -delete
kept="$(find "$BACKUP_DIR" -name 'logs-*.tar.gz' | wc -l)"

log "done: $size, $kept archives kept"
notify success "$(basename "$archive") ($size), $kept kept"
