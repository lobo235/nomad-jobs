job "mc-bedrock1" {
  node_pool = "beast2"
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

  group "mc-bedrock1" {
    count = 1

    network {
      port "minecraft1" {
        static = 19132
        to = 19132
      }
      port "minecraft2" {
        static = 19133
        to = 19133
      }
      mode = "bridge"
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "bedrock1"]
      port     = "minecraft1"
      provider = "consul"
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    ephemeral_disk {
      size = 500
    }

    task "mc-bedrock1" {
      driver = "docker"
      config {
        image = "itzg/minecraft-bedrock-server"
        ports = ["minecraft1", "minecraft2"]
        network_mode = "bridge"
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/bedrock1/data:/data"
        ]
      }

      resources {
        cores      = 2
        memory     = 2560  # 2.5GB
        memory_max = 3072  # 3GB
      }

      env {
        EULA = "TRUE"
        UID = 1001
        GID = 1001
        SERVER_NAME = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aBedrock1"
        MODE = "survival"
        DIFFICULTY = "hard"
        VIEW_DISTANCE = 6
        MAX_PLAYERS = 20
        ONLINE_MODE = "true"
        SEED = "Barlow Craft - Bedrock1"
        OPS = "netlobo"
        MOTD = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aBedrock1"
        MAX_MEMORY = "2G"
        VERSION = "LATEST"
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}
