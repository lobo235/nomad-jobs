job "mc-atm9" {
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

  group "mc-atm9" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
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
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "mc-atm9" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm9/data:/data",
          "/mnt/fast/minecraft/atm9/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm9/mods:/mods",
          "/mnt/fast/minecraft/atm9/config:/config",
          "/mnt/fast/minecraft/atm9/plugins:/plugins"
        ]
      }

      resources {
        cpu        = 12000
        memory     = 12288  # 12GB
      }

      env {
        EULA = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aATM9 v0.2.58"
        MODE = "survival"
        DIFFICULTY = "hard"
        ALLOW_FLIGHT = "TRUE"
        ENABLE_COMMAND_BLOCK = "TRUE"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 40
        SEED = "Barlow Craft - ATM9"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aATM9 v0.2.58"
        TYPE = "FORGE"
        GENERIC_PACK = "/modpacks/Server-Files-0.2.58.zip"
        VERSION = "1.20.1"
        FORGE_VERSION = "47.2.20"
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
