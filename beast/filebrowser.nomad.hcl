job "filebrowser" {
  node_pool  = "beast"
  datacenters = ["pondside"]
  type       = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }

  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "filebrowser" {
    count = 1

    network {
      port "http" {} # Let Nomad dynamically assign a port
    }

    service {
      name     = "filebrowser"
      port     = "http"
      provider = "consul"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.filebrowser.rule=Host(`files.big.netlobo.com`)",
        "traefik.http.routers.filebrowser.entrypoints=websecure",
        "traefik.http.routers.filebrowser.tls=true"
      ]

      check {
        type     = "http"
        path     = "/login"
        port     = "http"
        interval = "30s"
        timeout  = "15s"

        check_restart {
          limit = 3
          grace = "1m"
        }
      }
    }

    restart {
      attempts = 5
      interval = "5m"
      delay    = "30s"
      mode     = "delay"
    }

    task "filebrowser" {
      driver = "docker"

      config {
        image = "filebrowser/filebrowser:s6"
        ports = ["http"]
        volumes = [
          "/mnt/fast/filebrowser/srv:/srv",
          "/mnt/fast/filebrowser/database/:/database/",
          "/mnt/fast/filebrowser/config/:/config/"
        ]
      }

      resources {
        cpu    = 1000
        memory = 512
      }

      env {
        TZ = "America/Denver"
        PGID = 1002
        PUID = 1002
        UMASK = "022"
      }
    }
  }
}
