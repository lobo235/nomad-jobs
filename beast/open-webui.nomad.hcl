job "open-webui" {
  type        = "service"
  node_pool   = "beast"
  datacenters = ["pondside"]

  group "open-webui" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    update {
      healthy_deadline  = "10m"
      progress_deadline = "15m"
    }

    service {
      name     = "open-webui"
      port     = "http"
      provider = "consul"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.open-webui.rule=Host(`chat.big.netlobo.com`)",
        "traefik.http.routers.open-webui.entrypoints=websecure",
        "traefik.http.routers.open-webui.tls=true",
        "traefik.http.services.open-webui.loadbalancer.server.scheme=http"
      ]
      check {
        type     = "http"
        path     = "/api/v1/"
        port     = "http"
        interval = "30s"
        timeout  = "20s"
        check_restart {
          limit = 10
          grace = "3m"
        }
      }
    }

    vault {
      cluster     = "default"
      change_mode = "noop"
    }

    task "open-webui" {
      driver = "docker"

      config {
        image = "ghcr.io/open-webui/open-webui:main"
        ports = ["http"]

        volumes = [
          "/mnt/fast/openwebui:/app/backend/data"
        ]
      }

      template {
        data        = <<EOH
{{ with secret "kv/nomad/default/open-webui" }}
WEBUI_SECRET_KEY={{ .Data.data.webui_secret_key }}
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }

      env {
        # Point to Ollama via Consul DNS or direct URL
        # Using Consul DNS: ollama.service.consul
        # If Consul DNS isn't resolving inside Docker, use the Nomad
        # dynamic address instead and uncomment the template block below
        OLLAMA_BASE_URL = "https://ollama.big.netlobo.com"

        # Disable telemetry
        ANONYMIZED_TELEMETRY = "false"
        DO_NOT_TRACK         = "true"
        SCARF_NO_ANALYTICS   = "true"

        # First user to sign up becomes admin
        # Set to false after you've created your admin account
        ENABLE_SIGNUP = "true"

        # Increase timeouts for large model inference (CPU can be slow)
        AIOHTTP_CLIENT_TIMEOUT = "300"
      }

      resources {
        cpu    = 2000
        memory = 4096  # 4GB — Open WebUI itself is lightweight
      }
    }

    constraint {
      attribute = "${meta.nvidia_gpu}"
      value     = "true"
    }
  }
}
