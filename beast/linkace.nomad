job "linkace" {
  node_pool = "big"
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

  group "linkace" {
    count = 1

    network {
      port "linkace" {
        to = 80
      }
      mode = "bridge"
    }

    service {
      name     = "linkace"
      port     = "linkace"
      tags     = [
        "linkace",
        "traefik.enable=true",
        "traefik.http.routers.linkace.rule=Host(`linkace.big.netlobo.com`)",
        "traefik.http.routers.linkace.entrypoints=web"
      ]
      provider = "consul"

      check {
        type = "http"
        path = "/"
        port = "linkace"
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

    task "linkace" {
      driver = "docker"

      config {
        image = "linkace/linkace:latest"
        ports = ["linkace"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/linkace/app:/app"
        ]
      }

      resources {
        cores      = 1
        memory     = 256  # 256MB
        memory_max = 512  # 512MBB
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/linkace" -}}
DB_PASSWORD = {{ .db_password }}
{{- end -}}
EOF
      }

      env {
        DB_HOST = "mariadb.big.netlobo.com"
        DB_DATABASE = "linkace"
        DB_USERNAME = "linkace"
        TZ = "America/Denver"
      }
    }
  }
}