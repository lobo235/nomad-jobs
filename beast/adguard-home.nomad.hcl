job "adguard-home" {
  datacenters = ["pondside"]
  node_pool   = "hashi"
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "30s"
    healthy_deadline = "3m"
    auto_revert      = true
  }

  group "adguard" {
    count = 3

    network {
      port "dns" {
        static   = 53
      }
      port "http" {
        static = 8080
      }
      port "https" {
        static = 8443
      }
      port "quic" {
        static = 853
      }
    }

    task "adguard" {
      driver = "docker"

      config {
        image        = "adguard/adguardhome:latest"
        network_mode = "host"
        volumes = [
          "/opt/adguard/work:/opt/adguardhome/work",
          "/opt/adguard/conf:/opt/adguardhome/conf",
          "/mnt/fast/certs/big.netlobo.com:/cert"
        ]
      }

      env {
        TZ = "America/Denver"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      restart {
        mode     = "delay"
        delay    = "30s"
        interval = "5m"
      }

      service {
        name = "adguard-home"
        provider = "consul"
        port = "https"

        check {
          name     = "ui_https-port-tcp"
          type     = "http"
          protocol = "https"
          path = "/login.html"
          port     = "https"
          tls_skip_verify = "true"
          address_mode = "host"
          interval = "30s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "1m"
          }
        }
      }
    }
  }
}