job "sonarr" {
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

  group "sonarr" {
    count = 1

    network {
      port "sonarr" {
        to = 8989
      }
      mode = "bridge"
    }

    service {
      name     = "sonarr"
      port     = "sonarr"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.sonarr.rule=Host(`sonarr.big.netlobo.com`)",
        "traefik.http.routers.sonarr.entrypoints=websecure",
        "traefik.http.routers.sonarr.tls=true"
      ]

      check {
        type = "http"
        path = "/system/status"
        port = "sonarr"
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

    task "sonarr" {
      driver = "docker"

      config {
        image = "linuxserver/sonarr:latest"
        network_mode = "bridge"
        ports = ["sonarr"]
        # The "auth_soft_fail" configuration instructs Nomad to try public
        # repositories if the task fails to authenticate when pulling images
        # and the Docker driver has an "auth" configuration block.
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/sonarr/config:/config",
          "/mnt/media/tv:/tv",
          "/mnt/media/tv-hidden:/tv-hidden",
          "/mnt/plex/tv:/tv2",
          "/mnt/plex/tv-hidden:/tv2-hidden",
          "/mnt/fast/sabnzbd/downloads:/downloads"
        ]
      }

      resources {
        cpu        = 4000
        memory     = 8192   # 8GB
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
