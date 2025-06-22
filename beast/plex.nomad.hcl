job "plex" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type = "service"
  priority = 90

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

  group "plex" {
    count = 1

    network {
      port "plex" {
        static = 32400
      }
      mode = "host"
    }

    service {
      name     = "plex"
      port     = "plex"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.plex.rule=Host(`plex.big.netlobo.com`)",
        "traefik.http.routers.plex.entrypoints=websecure",
        "traefik.http.routers.plex.tls=true"
      ]

      check {
        type = "tcp"
        port = "plex"
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
      size = 3500
    }

    task "plex" {
      driver = "docker"

      config {
        image = "linuxserver/plex:latest"
        network_mode = "host"
        ports = ["plex"]
        #runtime = "nvidia"
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/plex/config:/config",
          "/mnt/media/tv:/tv",
          "/mnt/media/tv-hidden:/tv-hidden",
          "/mnt/media/movies:/movies",
          "/mnt/media/movies-hidden:/movies-hidden",
          "/mnt/media/music:/music",
          "/mnt/plex/tv:/tv2",
          "/mnt/plex/tv-hidden:/tv2-hidden",
          "/mnt/plex/movies:/movies2",
          "/mnt/plex/movies-hidden:/movies2-hidden",
          "/mnt/plex/music:/music2",
          "/mnt/fast/plex/transcode:/transcode"
        ]
        
        # Pass the GPU device
        devices = [
          {
            host_path      = "/dev/dri"
            container_path = "/dev/dri"
          }
        ]
      }

      resources {
        cpu        = 24000
        memory     = 16384  # 16GB
      }
      
      constraint {
        attribute = "${meta.intel_gpu}"
        value     = "true"
      }

      env {
        #NVIDIA_VISIBLE_DEVICES = "all"
        #NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility"
        PUID = 1002
        PGID = 1002
        VERSION = "docker"
        UMASK = "022"
      }
    }
  }
}