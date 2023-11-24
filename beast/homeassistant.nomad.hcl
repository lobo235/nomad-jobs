job "heimdall" {
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

  group "heimdall" {
    count = 1

    network {
      port "homeassistant" {
        static = 8123
      }
      mode = "host"
    }

    service {
      name     = "heimdall"
      port     = "heimdall"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.heimdall.rule=Host(`heimdall.big.netlobo.com`)",
        "traefik.http.routers.heimdall.entrypoints=websecure",
        "traefik.http.routers.heimdall.tls=true"
      ]

      check {
        type = "http"
        path = "/"
        port = "heimdall"
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

    task "heimdall" {
      driver = "docker"

      config {
        image = "linuxserver/homeassistant:latest"
        network_mode = "host"
        ports = ["heimdall", "heimdall_secure"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/heimdall/config:/config"
        ]
      }

      resources {
        cores      = 1
        memory     = 256  # 256MB
        memory_max = 512  # 512MB
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