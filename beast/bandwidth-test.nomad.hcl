job "bandwidth-test" {
  datacenters = ["pondside"]
  node_pool = "beast"
  type        = "service"

  group "k6-test" {
    count = 1

    task "k6" {
      driver = "docker"

      config {
        image   = "grafana/k6:latest"
        args    = ["run", "/data/test.js"]
        volumes = ["/mnt/fast/bandwidth-test:/data"]
      }

      resources {
        cpu    = 5000
        memory = 2048

        network {
          mode = "host"
        }
      }
    }
  }
}
