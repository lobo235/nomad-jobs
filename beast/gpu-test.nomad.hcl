job "gpu-test" {
  datacenters = ["pondside"]
  node_pool = "beast"
  type = "batch"

  group "smi" {
    task "smi" {
      driver = "docker"

      config {
        image = "nvidia/cuda:12.8.1-base-ubuntu22.04"
        command = "nvidia-smi"
      }

      resources {
        device "nvidia/gpu" {
          count = 1
        }
      }
    }
  }
}
