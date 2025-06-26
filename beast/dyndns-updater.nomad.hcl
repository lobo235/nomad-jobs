job "dyndns-updater" {
  node_pool  = "beast"
  datacenters = ["pondside"]
  type        = "service"

  update {
    max_parallel      = 1
    auto_revert       = false
    canary            = 0
  }

  migrate {
    max_parallel     = 1
  }

  group "dyndns-updater" {
    count = 1

    task "dyndns-updater" {
      driver = "docker"

      config {
        image = "ghcr.io/lobo235/dyndns-updater:latest"
        volumes = [
          "/mnt/fast/dyndns-updater/config:/config"
        ]
      }

      env {
        IP_FILE                = "/config/last_ip"
        IP_CHECK_URL_V4        = "https://api.ipify.org"
        IP_CHECK_URL_V6        = "https://api64.ipify.org"
        CHECK_INTERVAL_MINUTES = "1"
      }

      resources {
        cpu    = 100
        memory = 64
      }

      restart {
        attempts = 3
        interval = "30m"
        delay    = "30s"
        mode     = "delay"
      }

      service {
        name     = "dyndns-updater"
        provider = "consul"
        tags     = ["dyndns"]
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}
