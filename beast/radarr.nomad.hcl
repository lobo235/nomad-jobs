job "radarr" {
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

  group "radarr" {
    count = 1

    network {
      port "radarr" {
        to = 7878
      }
      mode = "bridge"
    }

    service {
      name     = "radarr"
      port     = "radarr"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.radarr.rule=Host(`radarr.big.netlobo.com`)",
        "traefik.http.routers.radarr.entrypoints=websecure",
        "traefik.http.routers.radarr.tls=true"
      ]

      check {
        type = "http"
        path = "/system/status"
        port = "radarr"
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

    task "radarr" {
      driver = "docker"

      config {
        image = "linuxserver/radarr:latest"
        network_mode = "bridge"
        ports = ["radarr"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/radarr/config:/config",
          "/mnt/media/downloads:/downloads",
          "/mnt/media/movies:/movies",
          "/mnt/media/movies-hidden:/movies-hidden",
          "/mnt/media2/downloads:/downloads2",
          "/mnt/media2/movies:/movies2",
          "/mnt/media2/movies-hidden:/movies2-hidden"
        ]
      }

      resources {
        cores      = 4
        memory     = 8192   # 8GB
        memory_max = 10240  # 10GB
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
