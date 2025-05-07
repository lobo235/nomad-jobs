job "mc-atm10s" {
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

  group "mc-atm10s" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
      
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "atm10s", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "atm10s.big.netlobo.com"
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

    task "mc-atm10s" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        entrypoint = ["/start-custom.sh"]
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm10s/data:/data",
          "/mnt/fast/minecraft/atm10s/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm10s/mods:/mods",
          "/mnt/fast/minecraft/atm10s/downloads:/downloads:ro",
          "/mnt/fast/minecraft/atm10s/start-custom.sh:/start-custom.sh:ro",
          "/mnt/fast/minecraft/atm10s/config:/config",
          "/mnt/fast/minecraft/atm10s/plugins:/plugins"
        ]
      }

      resources {
        cpu        = 36000
        memory     = 16384  # 16GB
      }

      meta {
        PACKVERSION = "2.47"
        NEOFORGE_VERSION = "21.1.168"
      }

      env {
        EULA = "TRUE"
        ENABLE_RCON = "TRUE"
        UID = 1001
        GID = 1001
        TZ = "America/Denver"
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
        USE_CUSTOM_START_SCRIPT = "true"
        TYPE = "CUSTOM"
        CUSTOM_JAR_EXEC = "@user_jvm_args.txt @libraries/net/neoforged/neoforge/${NOMAD_META_NEOFORGE_VERSION}/unix_args.txt nogui"
        VERSION = "1.21.1"
        PACKVERSION = "${NOMAD_META_PACKVERSION}"
        INIT_MEMORY = "4G"
        MAX_MEMORY = "14G"
        MAX_WORLD_SIZE = 16016
        MAX_TICK_TIME = 180000
        COPY_CONFIG_DEST= "/data/world/serverconfig"
        SYNC_SKIP_NEWER_IN_DESTINATION = "false"
        MAINTENANCE_MODE = "true"
      }
    }
  }
}
