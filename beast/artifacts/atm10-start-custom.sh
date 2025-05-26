#!/bin/bash

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "🧪 Running start-custom.sh for ATM10..."

set -e
cd /data

if [ -z "$PACKVERSION" ]; then
  log "❌ Environment variable PACKVERSION is not set. Please provide a version like 2.44"
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
  for item in "${BACKUP_TARGETS[@]}"; do
    if [ -e "$item" ]; then
      cp -r "$item" "$BACKUP_TEMP_DIR/"
    fi
  done

  tar --use-compress-program=pzstd -cf "$BACKUP_ARCHIVE" -C "$BACKUP_TEMP_DIR" .
  rm -rf "$BACKUP_TEMP_DIR"
  log "✅ Backup completed."

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

  sed -i '/^-Xms/d' user_jvm_args.txt
  sed -i '/^-Xmx/d' user_jvm_args.txt

  echo "$PACKVERSION" > .packversion
else
  log "✅ ServerFiles-${PACKVERSION} already unpacked and active."
fi

# Check if NeoForge is already installed
FORGE_JAR=$(find libraries -name 'neoforge-*-universal.jar' | head -n 1)
LIBS_EXIST=$(test -d libraries && echo yes || echo no)

if [ -z "$FORGE_JAR" ] || [ "$LIBS_EXIST" != "yes" ]; then
  NEOFORGE_INSTALLER=$(find . -name 'neoforge-*-installer.jar' | head -n 1)

  if [ -z "$NEOFORGE_INSTALLER" ]; then
    log "❌ NeoForge installer not found!"
    exit 1
  fi

  log "   Running NeoForge installer: $NEOFORGE_INSTALLER"
  java -jar "$NEOFORGE_INSTALLER" --installServer

  NEOFORGE_JAR=$(find libraries/net/neoforged/neoforge -name '*-universal.jar' | head -n 1)
  if [ -n "$NEOFORGE_JAR" ]; then
    log "✅ Found NeoForge jar at $NEOFORGE_JAR"
    log "📦 Copying to /data/server.jar"
    cp "$NEOFORGE_JAR" ./server.jar
  else
    log "❌ Could not locate NeoForge universal jar!"
    exit 1
  fi
else
  log "✅ NeoForge is already installed. Skipping install."
fi

log "📦 Fixing file permissions"
chown -R 1001:1001 /data

if [ "${MAINTENANCE_MODE:-false}" = "true" ]; then
  log "🛠 MAINTENANCE_MODE is enabled. Skipping server startup."
  log "📂 You can now exec into the container for maintenance."
  tail -f /dev/null
fi

log "🚀 Handoff to default /start script..."
exec /start
