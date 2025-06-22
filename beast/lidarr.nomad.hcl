job "lidarr" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "lidarr" {
    count = 1

    network {
      port "lidarr" {
        to = 8686
      }
    }

    service {
      name     = "lidarr"
      port     = "lidarr"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.lidarr.rule=Host(`lidarr.big.netlobo.com`)",
        "traefik.http.routers.lidarr.entrypoints=websecure",
        "traefik.http.routers.lidarr.tls=true"
      ]

      check {
        type = "http"
        path = "/system/status"
        port = "lidarr"
        interval = "30s"
        timeout = "20s"

        check_restart {
          limit = 3
          grace = "2m"
        }
      }
    }

    restart {
      attempts = 5
      interval = "5m"
      delay = "30s"
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    task "lidarr" {
      driver = "docker"

      config {
        image = "linuxserver/lidarr:latest"
        ports = ["lidarr"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/lidarr/config:/config",
          "/mnt/media/music:/music",
          "/mnt/plex/music:/music2",
          "/mnt/fast/sabnzbd/downloads:/downloads"
        ]
      }

      resources {
        cpu        = 2000
        memory     = 2048  # 2GB
      }

      env {
        PUID = 1002
        PGID = 1002
        TZ = "America/Denver"
        UMASK = "022"
      }
    }
  }
}
