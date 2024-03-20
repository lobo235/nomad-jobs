job "mc-ftb-revelation" {
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

  group "mc-ftb-revelation" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "ftb_revelation", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "revelation.big.netlobo.com"
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
      size = 15000
    }

    task "mc-ftb-revelation" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server:java8-multiarch"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/ftb_revelation/data:/data",
          "/mnt/fast/minecraft/ftb_revelation/mods:/mods"
        ]
      }

      resources {
        cores      = 4
        memory     = 12288  # 12GB
        memory_max = 14336  # 14GB
      }

      env {
        EULA = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aFTB Revelation §ev3.6.0"
        MODE = "survival"
        DIFFICULTY = "hard"
        ALLOW_FLIGHT = "TRUE"
        ENABLE_COMMAND_BLOCK = "TRUE"
        VIEW_DISTANCE = 10
        MAX_PLAYERS = 20
        SEED = "Barlow Craft - FTB Revelation"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aFTB Revelation \u00a7ev3.6.0"
        TYPE = "FTBA"
        FTB_MODPACK_ID = 35
        FTB_MODPACK_VERSION_ID = 2129
        MAX_MEMORY = "10G"
      }
    }
  }
}
