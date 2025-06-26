job "homeassistant" {
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

  group "homeassistant" {
    count = 1

    network {
      port "homeassistant" {
        static = 8123
      }
      mode = "host"
    }

    service {
      name     = "homeassistant"
      port     = "homeassistant"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.homeassistant.rule=Host(`homeassistant.big.netlobo.com`)",
        "traefik.http.routers.homeassistant.entrypoints=websecure",
        "traefik.http.routers.homeassistant.tls=true"
      ]

      check {
        type = "http"
        path = "/"
        port = "homeassistant"
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

    task "homeassistant" {
      driver = "docker"

      config {
        image = "linuxserver/homeassistant:latest"
        network_mode = "host"
        ports = ["homeassistant"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/homeassistant/config:/config"
        ]
      }

      resources {
        cores      = 2
        memory     = 1024  # 1GB
        memory_max = 1536  # 1.5GB
      }

      env {
        PUID = 1000
        PGID = 1000
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