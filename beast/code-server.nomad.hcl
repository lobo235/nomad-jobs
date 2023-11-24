job "code-server" {
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

  group "code-server" {
    count = 1

    network {
      port "code-server" {
        to = 8443
      }
      mode = "bridge"
    }

    service {
      name     = "code-server"
      port     = "code-server"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.code-server.rule=Host(`code-server.big.netlobo.com`)",
        "traefik.http.routers.code-server.entrypoints=websecure",
        "traefik.http.routers.code-server.tls=true"
      ]

       check {
        type = "http"
        path = "/healthz"
        port = "code-server"
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

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "code-server" {
      driver = "docker"

      config {
        image = "linuxserver/code-server:latest"
        network_mode = "bridge"
        ports = ["code-server"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/code-server/config:/config"
        ]
      }

      resources {
        cores      = 4
        memory     = 16384  # 16GB
        memory_max = 20480  # 20GB
      }

      env {
        PUID = 1000
        PGID = 1000
        TZ = "America/Denver"
        UMASK = "022"
      }

      template {
        data = <<EOH
PASSWORD={{ with secret "kv/nomad/default/code-server" }}{{ .Data.data.password }}{{ end }}
EOH
 
        env         = true
        destination = "${NOMAD_SECRETS_DIR}/code-server.env"
        change_mode = "restart"
      }
    }
  }
}
