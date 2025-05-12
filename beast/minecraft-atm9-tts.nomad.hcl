job "mc-atm9-tts" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type = "batch"

  periodic {
    crons = [
      "30 8 * * *",
      "30 20 * * *"
    ]
    time_zone         = "America/Denver"
    prohibit_overlap  = true
  }

  group "mc-atm9-tts" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
      
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "atm9-tts", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "atm9-tts.big.netlobo.com"
      }

      check {
        name     = "alive"
        type     = "tcp"
        interval = "30s"
        timeout  = "5s"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "mc-atm9-tts" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm9-tts/data:/data",
          "/mnt/fast/minecraft/atm9-tts/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm9-tts/mods:/mods",
          "/mnt/fast/minecraft/atm9-tts/config:/config",
          "/mnt/fast/minecraft/atm9-tts/plugins:/plugins"
        ]
      }

      template {
        data        = <<EOH
{{ with secret "kv/nomad/default/mc-atm9-tts" }}
CF_API_KEY={{ .Data.data.curseforge_apikey }}
RCON_PASSWORD={{ .Data.data.rcon_password }}
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }

      resources {
        cpu        = 12000
        memory     = 12288  # 12GB
      }

      meta {
        PACKVERSION = "1.1.5"
      }

      env {
        EULA = "TRUE"
        ENABLE_RCON = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aATM9 - To The Sky v${NOMAD_META_PACKVERSION}"
        MODE = "survival"
        DIFFICULTY = "hard"
        ALLOW_FLIGHT = "TRUE"
        ENABLE_COMMAND_BLOCK = "TRUE"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 40
        SEED = "Barlow Craft - ATM9 - To The Sky"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aATM9 - To The Sky v${NOMAD_META_PACKVERSION}"
        TYPE = "AUTO_CURSEFORGE"
        CF_SLUG = "all-the-mods-9-to-the-sky"
        CF_FILENAME_MATCHER = "${NOMAD_META_PACKVERSION}"
        VERSION = "1.20.1"
        MAX_MEMORY = "10G"
        MAX_WORLD_SIZE = 16016
        MAX_TICK_TIME = -1
        COPY_CONFIG_DEST= "/data/world/serverconfig"
        SYNC_SKIP_NEWER_IN_DESTINATION = "false"
        JVM_OPTS = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=32M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
      }
    }
  }
}
