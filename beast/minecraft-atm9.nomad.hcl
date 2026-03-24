job "mc-atm9" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type = "service"

  group "mc-atm9" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
      port "rcon" {
        to = 25575
      }
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "atm9", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "atm9.big.netlobo.com"
      }

      check {
        name     = "alive"
        type     = "tcp"
        interval = "30s"
        timeout  = "5s"
      }
    }

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "mc-atm9" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        entrypoint = ["/local/entrypoint.sh"]
        ports = ["minecraft", "rcon"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm9/data:/data",
          "/mnt/fast/minecraft/atm9/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm9/mods:/mods",
          "/mnt/fast/minecraft/atm9/downloads:/downloads:ro",
          "/mnt/fast/minecraft/atm9/config:/config",
          "/mnt/fast/minecraft/atm9/plugins:/plugins"
        ]
      }

      template {
        data = <<EOF
{{ with secret "kv/nomad/default/mc-atm9" }}
RCON_PASSWORD={{ .Data.data.rcon_password }}
{{ end }}
EOF
        destination = "secrets/mc-atm9.env"
        env         = true
      }

      resources {
        cpu        = 28000
        memory     = 16384  # 16GB
      }

      artifact {
        source      = "https://raw.githubusercontent.com/lobo235/nomad-jobs/refs/heads/main/beast/artifacts/atm9-start-custom.sh"
        options {
          filename  = "start-custom.sh"
        }
      }

      artifact {
        source      = "https://raw.githubusercontent.com/lobo235/nomad-jobs/refs/heads/main/beast/artifacts/atm9-restore-backup.sh"
        options {
          filename  = "restore-backup.sh"
        }
      }

      template {
        data = <<EOF
#!/bin/sh
chmod +x /local/start-custom.sh
chmod +x /local/restore-backup.sh
exec /local/start-custom.sh
EOF
        destination = "local/entrypoint.sh"
        perms       = "0755"
      }

      kill_timeout = "120s"

      meta {
        PACKVERSION = "1.0.8"
      }

      env {
        PACKVERSION = "${NOMAD_META_PACKVERSION}"
        CUSTOM_SERVER = "/data/startserver.sh"
        MAINTENANCE_MODE = "false"
        EULA = "TRUE"
        ENABLE_RCON = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aATM9 v${NOMAD_META_PACKVERSION}"
        MODE = "survival"
        DIFFICULTY = "hard"
        ALLOW_FLIGHT = "TRUE"
        ENABLE_COMMAND_BLOCK = "TRUE"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 40
        SEED = "Barlow Craft - ATM9"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aATM9 v${NOMAD_META_PACKVERSION}"
        USE_CUSTOM_START_SCRIPT = "true"
        TYPE = "CUSTOM"
        VERSION = "1.20.1"
        INIT_MEMORY = "8G"
        MAX_MEMORY = "14G"
        MAX_WORLD_SIZE = 16016
        MAX_TICK_TIME = -1
        COPY_CONFIG_DEST = "/data/world/serverconfig"
        SYNC_SKIP_NEWER_IN_DESTINATION = "false"
        JVM_OPTS = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=32M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
      }
    }

    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}