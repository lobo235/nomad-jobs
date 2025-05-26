#!/bin/bash

set -e

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

if [ -z "$1" ]; then
  echo "Usage: $0 <backup-file.tar.zst> [--force]"
  echo "Example: $0 /data/backups/upgrades/2.43-20240524-103215.tar.zst"
  exit 1
fi

BACKUP_FILE="$1"
FORCE=${2:-""}

if [ ! -f "$BACKUP_FILE" ]; then
  log "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

if [ "$FORCE" != "--force" ]; then
  echo "⚠️  This will delete current server data and restore from backup:"
  echo "   $BACKUP_FILE"
  echo -n "Are you absolutely sure? Type 'yes' to proceed: "
  read -r CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    log "❌ Restore aborted by user."
    exit 1
  fi
fi

log "🧹 Deleting existing world, configs, and runtime data..."
cd /data
rm -rf world logs server.properties banned-players.json ops.json whitelist.json usercache.json config .packversion

log "📦 Extracting backup: $BACKUP_FILE"
tar --use-compress-program="zstd -d" -xf "$BACKUP_FILE" -C /data

log "🔧 Fixing file permissions..."
chown -R 1001:1001 /data

log "✅ Restore complete."

exit 0
