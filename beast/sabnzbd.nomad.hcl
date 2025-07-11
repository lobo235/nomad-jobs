job "sabnzbd" {
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

  group "sabnzbd" {
    count = 1

    network {
      port "sabnzbd" {
        to = 8090
      }
      port "sabnzbd_tls" {
        to = 9090
      }
    }

    service {
      name     = "sabnzbd"
      port     = "sabnzbd"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.sabnzbd.rule=Host(`sabnzbd.big.netlobo.com`)",
        "traefik.http.routers.sabnzbd.entrypoints=websecure",
        "traefik.http.routers.sabnzbd.tls=true"
      ]

      check {
        type = "http"
        path = "/sabnzbd/"
        port = "sabnzbd"
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

    task "sabnzbd" {
      driver = "docker"
      config {
        image = "linuxserver/sabnzbd:latest"
        ports = ["sabnzbd","sabnzbd_tls"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/sabnzbd/config:/config",
          "/mnt/media/music:/music",
          "/mnt/media/tv:/tv",
          "/mnt/media/tv-hidden:/tv-hidden",
          "/mnt/media/movies:/movies",
          "/mnt/media/movies-hidden:/movies-hidden",
          "/mnt/plex/music:/music2",
          "/mnt/plex/tv:/tv2",
          "/mnt/plex/tv-hidden:/tv2-hidden",
          "/mnt/plex/movies:/movies2",
          "/mnt/plex/movies-hidden:/movies2-hidden",
          "/mnt/fast/sabnzbd/incomplete-downloads:/incomplete-downloads",
          "/mnt/fast/sabnzbd/downloads:/downloads"
        ]
      }

      resources {
        cpu        = 4000
        memory     = 34816  # 34GB
      }

      env {
        PUID = 1002
        PGID = 1002
        TZ = "America/Denver"
        UMASK = "022"
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}
