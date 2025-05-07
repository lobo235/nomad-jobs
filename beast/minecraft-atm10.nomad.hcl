job "mc-atm10" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "10m"
    progress_deadline = "20m"
    auto_revert = false
    canary = 0
  }

  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "10m"
  }

  group "mc-atm10" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
      
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "atm10", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "atm10.big.netlobo.com"
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

    task "mc-atm10" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm10/data:/data",
          "/mnt/fast/minecraft/atm10/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm10/mods:/mods",
          "/mnt/fast/minecraft/atm10/config:/config",
          "/mnt/fast/minecraft/atm10/plugins:/plugins"
        ]
      }

      template {
        data        = <<EOH
{{ with secret "kv/nomad/default/mc-atm10" }}
CF_API_KEY={{ .Data.data.curseforge_apikey }}
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }

      resources {
        cpu        = 36000
        memory     = 16384  # 16GB
      }

      meta {
        PACKVERSION = "2.46"
      }

      env {
        EULA = "TRUE"
        ENABLE_RCON = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aATM10 v${NOMAD_META_PACKVERSION}"
        MODE = "survival"
        DIFFICULTY = "hard"
        ALLOW_FLIGHT = "TRUE"
        ENABLE_COMMAND_BLOCK = "TRUE"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 40
        SEED = "Barlow Craft - ATM10"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aATM10 v${NOMAD_META_PACKVERSION}"
        MOD_PLATFORM = "AUTO_CURSEFORGE"
        CF_SLUG = "all-the-mods-10"
        CF_FILENAME_MATCHER = "${NOMAD_META_PACKVERSION}"
        CF_EXCLUDE_MODS = "986380, 520110, 394468, 447673, 583228, 1133580" # 1133580(SmithingTemplateViewer)
        CF_OVERRIDES_EXCLUSIONS = "shaderpacks/**"
        MAX_MEMORY = "14G"
        MAX_WORLD_SIZE = 16016
        MAX_TICK_TIME = -1
        COPY_CONFIG_DEST= "/data/world/serverconfig"
        SYNC_SKIP_NEWER_IN_DESTINATION = "false"
        JVM_OPTS = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=32M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
        # NEW JVM_OPTS = "-XX:+UseZGC -XX:+ZGenerational -XX:SoftMaxHeapSize=10g -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem -XX:+UseDynamicNumberOfGCThreads"
      }
    }
  }
}
