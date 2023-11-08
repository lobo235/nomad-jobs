job "mc-router" {
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

  group "mc-router" {
    count = 1

    network {
      port "minecraft" {
        static = 25565
      }
      port "api" {
        static = 7069
      }
    }

    service {
      name     = "mc-router"
      tags     = ["global", "minecraft", "tcp"]
      port     = "minecraft"
      provider = "consul"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "minecraft"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name     = "mc-router-api"
      tags     = ["global", "tcp"]
      port     = "api"
      provider = "consul"
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "delay"
    }

    task "mc-router" {
      driver = "docker"

      config {
        image = "itzg/mc-router"
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/mc-router/:/configs"
        ]
      }

      resources {
        cpu        = 2000  # 2000Mhz
        memory     = 128 # 128MB
        memory_max = 256 # 256MB
      }

      template {
        data        = <<EOF
MAPPING={{ $first := true }}{{- range service "mc-router-register.minecraft" }}{{ if $first }}{{ $first = false }}{{ else }},{{ end }}{{ .ServiceMeta.externalServerName }}={{ .Address }}:{{ .Port }}{{ end -}}
EOF
        destination = "local/mapping.env"
        env         = true
      }

      env {
        API_BINDING = ":${NOMAD_PORT_api}"
      }
    }
  }
}
