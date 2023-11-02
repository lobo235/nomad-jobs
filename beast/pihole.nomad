job "pihole" {
  node_pool = "hashi"
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

  group "pihole" {
    count = 3

    network {
      mode = "bridge"

      port "dns-tcp" {
        to = 53
      }
      port "dns-udp" {
        to = 53
      }
      port "ui" {
        to = 80
      }
    }

    service {
      name     = "pihole-dns-tcp"
      port     = "dns-tcp"
      tags     = [
        "traefik.enable=true",
        "traefik.tcp.routers.pihole-dns-tcp.rule=HostSNI(`*`)",
        "traefik.tcp.services.pihole-dns-tcp.loadbalancer.server.port=53",
        "traefik.tcp.routers.pihole-dns-tcp.entrypoints=pihole-dns-tcp"
      ]
      provider = "consul"

      check {
        type = "tcp"
        port = "dns-tcp"
        interval = "30s"
        timeout = "20s"

        check_restart {
          limit = 3
          grace = "2m"
        }
      }
    }

    service {
      name     = "pihole-dns-udp"
      port     = "dns-udp"
      tags     = [
        "traefik.enable=true",
        "traefik.udp.services.pihole-dns-udp.loadbalancer.server.port=53",
        "traefik.udp.routers.pihole-dns-udp.entrypoints=pihole-dns-udp"
      ]
      provider = "consul"
    }

    service {
      name     = "pihole-ui"
      port     = "ui"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.pihole-ui.rule=Host(`*`)",
        "traefik.http.routers.pihole-ui.entrypoints=pihole-ui"
      ]
      provider = "consul"

      check {
        type = "tcp"
        port = "ui"
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

    task "pihole" {
      driver = "docker"

      config {
        image = "pihole/pihole:latest"
        network_mode = "bridge"
        ports = ["dns-tcp", "dns-udp", "ui"]
        auth_soft_fail = true
        volumes = [
          "local/etc-pihole:/etc/pihole",
          "local/etc-dnsmasq.d:/etc/dnsmasq.d"
        ]
      }

      resources {
        cpu        = 800
        memory     = 512  # 512MB
      }

      env {
        TZ = "America/Denver"
        WEBPASSWORD = "jZKbBVwa3WbbVi.KhZA"
      }
    }
  }
}
