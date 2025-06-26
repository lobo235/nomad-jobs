job "mariadb" {
  type      = "service"
  node_pool = "beast"

  group "mariadb" {
    count = 1
    network {
      port "mariadb" {
        to = 3306
      }
    }

    service {
      name     = "mariadb-svc"
      port     = "mariadb"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.tcp.routers.mariadb-svc.rule=HostSNI(`*`)",
        "traefik.tcp.routers.mariadb-svc.entrypoints=mariadb"
      ]

      check {
        type     = "tcp"
        port     = "mariadb"
        interval = "30s"
        timeout  = "20s"

        check_restart {
          limit = 3
          grace = "2m"
        }
      }
    }

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "mariadb-task" {
      driver = "docker"
      template {
        data        = <<EOH
{{ with secret "kv/nomad/default/mariadb" }}
MARIADB_PASSWORD={{ .Data.data.password }}
MARIADB_ROOT_PASSWORD={{ .Data.data.root_password }}
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
      env {
        MARIADB_AUTO_UPGRADE       = "1"
        MARIADB_INITDB_SKIP_TZINFO = "1"
        MARIADB_DATABASE           = "netlobo"
        MARIADB_USER               = "bpexp235"
      }
      resources {
        cpu    = 4000
        memory = 4096 # 4GB
      }
      config {
        image   = "mariadb:10.11"
        ports   = ["mariadb"]
        command = "mariadbd"
        args = [
          "--innodb-buffer-pool-size=512M", "--transaction-isolation=READ-COMMITTED",
          "--character-set-server=utf8mb4",
          "--collation-server=utf8mb4_unicode_ci",
          "--max-connections=512",
          "--innodb-rollback-on-timeout=OFF",
          "--innodb-lock-wait-timeout=120",
        ]
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}