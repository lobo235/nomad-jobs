job "netlobo-linodedyndns" {
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

  group "netlobo-linodedyndns" {
    count = 1

    restart {
      attempts = 5
      interval = "5m"
      delay = "30s"
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    vault {
      cluster = "default"
      change_mode = "noop"
    }

    task "netlobo-linodedyndns-pondside" {
      driver = "docker"

      config {
        image = "bpexp235/netlobo-linodedyndns:latest"
        auth_soft_fail = true
      }

      resources {
        cpu        = 100 # 100MHz
        memory     = 64 # 64M
      }

      env {
        DOMAIN_NAME = "netlobo.com"
        A_RECORD = "pondside"
      }

      template {
        data = <<EOH
LINODE_API_KEY={{ with secret "kv/nomad/default/netlobo-linodedyndns" }}{{ .Data.data.linode_api_key }}{{ end }}
EOH
 
        env         = true
        destination = "${NOMAD_SECRETS_DIR}/netlobo-linodedyndns.env"
        change_mode = "restart"
      }
    }
    task "netlobo-linodedyndns-big" {
      driver = "docker"

      config {
        image = "bpexp235/netlobo-linodedyndns:latest"
        # The "auth_soft_fail" configuration instructs Nomad to try public
        # repositories if the task fails to authenticate when pulling images
        # and the Docker driver has an "auth" configuration block.
        auth_soft_fail = true
      }

      resources {
        cpu        = 100 # 100MHz
        memory     = 64 # 64M
      }

      env {
        DOMAIN_NAME = "netlobo.com"
        A_RECORD = "big"
        WAN_IP_PROVIDER = "ip.me"
      }

      template {
        data = <<EOH
LINODE_API_KEY={{ with secret "kv/nomad/default/netlobo-linodedyndns" }}{{ .Data.data.linode_api_key }}{{ end }}
EOH
 
        env         = true
        destination = "${NOMAD_SECRETS_DIR}/netlobo-linodedyndns.env"
        change_mode = "restart"
      }
    }
  }
}
