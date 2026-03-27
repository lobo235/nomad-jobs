job "ollama" {
  type        = "service"
  node_pool   = "beast"
  datacenters = ["pondside"]

  group "ollama" {
    count = 1

    network {
      port "http" {
        to = 11434
      }
    }

    update {
      healthy_deadline  = "10m"
      progress_deadline = "15m"
    }

    service {
      name     = "ollama"
      port     = "http"
      provider = "consul"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.ollama.rule=Host(`ollama.big.netlobo.com`)",
        "traefik.http.routers.ollama.entrypoints=websecure",
        "traefik.http.routers.ollama.tls=true",
        "traefik.http.services.ollama.loadbalancer.server.scheme=http"
      ]
      check {
        type     = "http"
        path     = "/"
        port     = "http"
        interval = "30s"
        timeout  = "10s"
        check_restart {
          limit = 5
          grace = "2m"
        }
      }
    }

    task "ollama" {
      driver = "docker"

      config {
        image = "ollama/ollama:latest"
        ports = ["http"]
        runtime = "nvidia"

        volumes = [
          "/mnt/fast/ollama:/root/.ollama"
        ]
      }

      env {
        # Listen on all interfaces inside the container
        OLLAMA_HOST = "0.0.0.0"

        # Keep models loaded for 10 minutes of idle before unloading
        OLLAMA_KEEP_ALIVE = "10m"

        # Allow up to 2 concurrent inference requests
        OLLAMA_NUM_PARALLEL = "2"

        # Allow up to 2 models loaded simultaneously
        OLLAMA_MAX_LOADED_MODELS = "2"

        # Enable flash attention for better memory efficiency
        OLLAMA_FLASH_ATTENTION = "1"

        # Nvidia driver capabilities needed inside the container
        NVIDIA_VISIBLE_DEVICES = "all"
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility"
      }

      resources {
        cpu        = 40000  # ~40 cores worth for CPU inference layers
        memory     = 200000 # ~200GB — room for large models + OS overhead
      }
    }

    constraint {
      attribute = "${meta.nvidia_gpu}"
      value     = "true"
    }
  }
}
