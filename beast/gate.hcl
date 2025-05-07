job "gate" {
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

  group "gate" {
    count = 1

    network {
      port "minecraft" {
        static = 25565
      }
    }

    service {
      name     = "gate"
      tags     = ["global", "minecraft", "tcp"]
      port     = "minecraft"
      provider = "consul"
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "delay"
    }

    task "gate" {
      driver = "docker"

      config {
        image = "ghcr.io/minekube/gate:latest"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "local/config.yml:/config.yml"
        ]
      }

      resources {
        cpu        = 2000  # 2000Mhz
        memory     = 256 # 256MB
      }

      template {
        data = <<-EOT
          config:
            bind: 0.0.0.0:25565
            shutdownReason: |
              §cProxy server is shutting down...
              Please reconnect in a moment!
            readTimeout: 60s
            lite:
              enabled: true
              routes:
              {{- range service "mc-router-register.minecraft|passing" }}
                - host: {{ .ServiceMeta.externalServerName }}
                  backend: {{ .Address }}:{{ .Port }}
                  cachePingTTL: -1s
                  proxyProtocol: true
              {{- end }}
              fallback:
                motd: |
                  §cServer is restarting.
                  §eCheck back later!
                version:
                  name: '§cTry again later!'
                  protocol: -1
        EOT

        destination = "local/config.yml"
        change_mode = "restart"
      }
    }
  }
}
