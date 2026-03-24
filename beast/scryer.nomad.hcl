job "scryer" {
  type        = "service"
  node_pool   = "beast"
  datacenters = ["pondside"]

  group "scryer" {
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
      name     = "scryer"
      port     = "http"
      provider = "consul"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.scryer.rule=Host(`scryer.big.netlobo.com`)",
        "traefik.http.routers.scryer.entrypoints=websecure",
        "traefik.http.routers.scryer.tls=true",
        "traefik.http.services.scryer.loadbalancer.server.scheme=http"
      ]
      check {
        type     = "http"
        path     = "/health"
        port     = "http"
        interval = "30s"
        timeout  = "10s"
        check_restart {
          limit = 5
          grace = "1m"
        }
      }
    }

    vault {
      cluster     = "default"
      change_mode = "noop"
    }

    task "scryer" {
      driver = "docker"

      config {
        image = "ghcr.io/scryer-media/scryer:0.9.0"
        ports = ["http"]
        volumes = [
          "/mnt/fast/scryer/data:/data",
          "/mnt/fast/scryer/config:/config",
          "/mnt/plex/movies2:/movies2",
          "/mnt/plex/tv2:/tv2"
        ]
      }

      env {
        PUID                              = 1002
        PGID                              = 1002
        SCRYER_MOVIES_PATH                = "/movies2"
        SCRYER_SERIES_PATH                = "/tv2"
        SCRYER_METADATA_GATEWAY_GRAPHQL_URL = "https://smg.scryer.media/graphql"
      }

      template {
        data = <<EOH
SCRYER_ENCRYPTION_KEY={{ with secret "kv/nomad/default/scryer" }}{{ .Data.data.encryption_key }}{{ end }}
EOH

        env         = true
        destination = "${NOMAD_SECRETS_DIR}/scryer.env"
        change_mode = "restart"
      }

      resources {
        cpu    = 4000
        memory = 512
      }
    }
  }
}
