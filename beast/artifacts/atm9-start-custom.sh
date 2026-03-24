#!/bin/bash

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "🧪 Running start-custom.sh for ATM9..."

set -e
cd /data

if [ -z "$PACKVERSION" ]; then
  log "❌ Environment variable PACKVERSION is not set. Please provide a version like 1.0.8"
  exit 1
fi

ZIP_FILE="/downloads/ServerFiles-${PACKVERSION}.zip"

if [ ! -f "$ZIP_FILE" ]; then
  log "❌ Expected file not found: $ZIP_FILE"
  log "📁 Available files in /downloads:"
  ls -1 /downloads/ServerFiles-*.zip || log "(none)"
  exit 1
fi

# Check installed version
if [ -f ".packversion" ]; then
  INSTALLED_VERSION=$(cat .packversion)
else
  INSTALLED_VERSION="none"
fi

if [ "$INSTALLED_VERSION" != "$PACKVERSION" ]; then
  log "🔄 Detected version change: $INSTALLED_VERSION → $PACKVERSION"

  # Backup critical data
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_TEMP_DIR="/data/backups/upgrades/${INSTALLED_VERSION}-${TIMESTAMP}"
  BACKUP_ARCHIVE="/data/backups/upgrades/${INSTALLED_VERSION}-${TIMESTAMP}.tar.zst"
  mkdir -p "$BACKUP_TEMP_DIR"

  BACKUP_TARGETS=(
    "world"
    "logs"
    "server.properties"
    "banned-players.json"
    "ops.json"
    "whitelist.json"
    "usercache.json"
    "config"
    ".packversion"
  )

  log "🗄️  Backing up important data to $BACKUP_ARCHIVE..."
  backup_start=$(date +%s)

  for item in "${BACKUP_TARGETS[@]}"; do
    if [ -e "$item" ]; then
      log "📁 Backing up: $item"
      if [ -d "$item" ]; then
        mkdir -p "$BACKUP_TEMP_DIR/$item"
        total_size=$(du -sh "$item" | cut -f1)

        rsync -a -h "$item"/ "$BACKUP_TEMP_DIR/$item/" &
        RSYNC_PID=$!

        while kill -0 "$RSYNC_PID" 2>/dev/null; do
          copied_size=$(du -sh "$BACKUP_TEMP_DIR/$item" | cut -f1)
          log "📏 Rsync progress for $item: $copied_size / $total_size copied..."
          sleep 10
        done

        wait "$RSYNC_PID"
        RSYNC_EXIT=$?

        if [ $RSYNC_EXIT -ne 0 ]; then
          log "❌ Rsync failed for $item with exit code $RSYNC_EXIT"
          exit 1
        fi

        log "✅ Finished rsync for $item"
      else
        mkdir -p "$(dirname "$BACKUP_TEMP_DIR/$item")"
        rsync -a -h "$item" "$BACKUP_TEMP_DIR/$item" >/dev/null
        log "✅ Copied file: $item"
      fi
    else
      log "⚠️  Skipped (not found): $item"
    fi
  done

  backup_end=$(date +%s)
  backup_duration=$((backup_end - backup_start))
  log "✅ File copy complete. Backup completed in ${backup_duration}s."

  log "🗜️  Creating compressed archive..."
  archive_start=$(date +%s)

  total_uncompressed=$(du -sh "$BACKUP_TEMP_DIR" | cut -f1)

  tar --use-compress-program=pzstd -cf "$BACKUP_ARCHIVE" -C "$BACKUP_TEMP_DIR" . &
  TAR_PID=$!

  while kill -0 "$TAR_PID" 2>/dev/null; do
    if [ -f "$BACKUP_ARCHIVE" ]; then
      archive_size=$(du -sh "$BACKUP_ARCHIVE" | cut -f1)
      log "📏 Archive size so far: $archive_size (compressed) / $total_uncompressed (uncompressed)"
    else
      log "⌛ Waiting for archive to be created..."
    fi
    sleep 10
  done

  wait "$TAR_PID"
  ARCHIVE_EXIT=$?

  if [ $ARCHIVE_EXIT -ne 0 ]; then
    log "❌ Archive creation failed with exit code $ARCHIVE_EXIT"
    exit 1
  fi

  archive_end=$(date +%s)
  archive_duration=$((archive_end - archive_start))
  final_size=$(du -sh "$BACKUP_ARCHIVE" | cut -f1)
  log "✅ Backup completed. Final archive size: $final_size (compressed) / $total_uncompressed (uncompressed)"
  log "✅ Archive completed in ${archive_duration}s."

  log "🧹 Cleaning up temporary backup directory..."
  rm -rf "$BACKUP_TEMP_DIR"

  log "🧹 Cleaning old server files..."
  find . -mindepth 1 -maxdepth 1 \
    ! -name "ServerFiles-${PACKVERSION}.zip" \
    ! -name ".packversion" \
    ! -name "backups" \
    ! -name "world" \
    ! -name "logs" \
    -exec rm -rf {} +

  log "📦 Unpacking $ZIP_FILE..."
  unzip -o "$ZIP_FILE" -d /data

  # JVM cleanup if file exists
  if [ -f user_jvm_args.txt ]; then
    sed -i '/^-Xms/d' user_jvm_args.txt
    sed -i '/^-Xmx/d' user_jvm_args.txt
  else
    log "⚠️  user_jvm_args.txt not found — skipping JVM arg cleanup."
  fi

  echo "$PACKVERSION" > .packversion
else
  log "✅ ServerFiles-${PACKVERSION} already unpacked and active."
fi

log "📦 Fixing file permissions"
chown -R 1001:1001 /data

if [ "${MAINTENANCE_MODE:-false}" = "true" ]; then
  log "🛠 MAINTENANCE_MODE is enabled. Skipping server startup."
  log "📂 You can now exec into the container for maintenance."
  tail -f /dev/null
fi

# JVM cleanup again on runtime if file exists
if [ -f user_jvm_args.txt ]; then
  sed -i '/^-Xms/d' user_jvm_args.txt
  sed -i '/^-Xmx/d' user_jvm_args.txt
else
  log "⚠️  user_jvm_args.txt not found — skipping JVM arg cleanup."
fi

log "🚀 Handoff to default /start script..."
exec /start