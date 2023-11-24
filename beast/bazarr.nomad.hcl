job "bazarr" {
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

  group "bazarr" {
    count = 1

    network {
      port "bazarr" {
        to = 6767
      }
      mode = "bridge"
    }

    service {
      name     = "bazarr"
      port     = "bazarr"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.bazarr.rule=Host(`bazarr.big.netlobo.com`)",
        "traefik.http.routers.bazarr.entrypoints=websecure",
        "traefik.http.routers.bazarr.tls=true"
      ]

      check {
        type = "http"
        path = "/system/status"
        port = "bazarr"
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

    task "bazarr" {
      driver = "docker"

      config {
        image = "linuxserver/bazarr:latest"
        network_mode = "bridge"
        ports = ["bazarr"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/bazarr/config:/config",
          "/mnt/media/downloads:/downloads",
          "/mnt/media/movies:/movies",
          "/mnt/media/movies-hidden:/movies-hidden",
          "/mnt/media/tv:/tv",
          "/mnt/media/tv-hidden:/tv-hidden",
          "/mnt/plex/downloads:/downloads2",
          "/mnt/plex/movies:/movies2",
          "/mnt/plex/movies-hidden:/movies2-hidden",
          "/mnt/plex/tv:/tv2",
          "/mnt/plex/tv-hidden:/tv2-hidden"
        ]
      }

      resources {
        cores      = 1
        memory     = 2048  # 2GB
        memory_max = 2560  # 2.5GB
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
