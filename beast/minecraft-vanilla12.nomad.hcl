job "mc-vanilla12" {
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

  group "mc-vanilla12" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "vanilla12", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "vanilla12.big.netlobo.com"
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

    task "mc-vanilla12" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/vanilla12/data:/data"
        ]
      }

      resources {
        cpu        = 8000
        memory     = 4096  # 4GB
      }

      env {
        EULA = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "Barlow Craft - Vanilla12"
        MODE = "survival"
        DIFFICULTY = "hard"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 20
        SEED = "Barlow Craft - Vanilla12-1"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aVanilla12"
        MAX_MEMORY = "3G"
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}
