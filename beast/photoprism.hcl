job "photoprism" {
  type      = "service"
  node_pool = "beast"
  datacenters = ["pondside"]

  group "photoprism" {
    count = 1
    network {
      port "https" {
        to = 2342
      }
    }

    update {
      healthy_deadline = "10m"
      progress_deadline = "20m"
    }

    service {
      name     = "photoprism"
      port     = "https"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.photoprism.rule=Host(`photoprism.big.netlobo.com`)",
        "traefik.http.routers.photoprism.entrypoints=websecure",
        "traefik.http.routers.photoprism.tls=true",
        "traefik.http.services.photoprism.loadbalancer.server.scheme=https"
      ]

      check {
        type = "http"
        protocol = "https"
        tls_skip_verify  = true
        path = "/library/about"
        port = "https"
        interval = "30s"
        timeout = "20s"

        check_restart {
          limit = 3
          grace = "2m"
        }
      }
    }

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "photoprism" {
      driver = "docker"

      config {
        image = "photoprism/photoprism:latest"
        ports = ["https"]
        args = []
        runtime = "nvidia"
        volumes = [
          "/mnt/photos/originals:/photoprism/originals",
          "/mnt/photos/import:/photoprism/import",
          "/mnt/fast/photoprism:/photoprism/storage"
        ]
      }

      template {
        data        = <<EOH
{{ with secret "kv/nomad/default/photoprism" }}
PHOTOPRISM_ADMIN_PASSWORD={{ .Data.data.admin_password }}
PHOTOPRISM_DATABASE_PASSWORD={{ .Data.data.db_password }}
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }

      env {
        PHOTOPRISM_ADMIN_USER = "admin"
        PHOTOPRISM_SITE_URL = "https://photoprism.big.netlobo.com/"
        PHOTOPRISM_ORIGINALS_LIMIT = 20000
        PHOTOPRISM_DATABASE_SERVER = "mariadb.big.netlobo.com:3306"
        PHOTOPRISM_FFMPEG_ENCODER = "nvidia"
        PHOTOPRISM_FFMPEG_SIZE = 7680
        PHOTOPRISM_DISABLE_TLS = false
        PHOTOPRISM_DEFAULT_TLS = true
        PHOTOPRISM_INIT = "https gpu tensorflow"
        PHOTOPRISM_UID = 1000
        PHOTOPRISM_GID = 1000
        PHOTOPRISM_UMASK = 0022
        PHOTOPRISM_LOG_LEVEL = "trace"
        NVIDIA_VISIBLE_DEVICES = "all"
        NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility"
      }

      resources {
        cpu        = 6000
        memory     = 16384  # 16GB
      }
    }
  }
}