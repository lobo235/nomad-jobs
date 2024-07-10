job "openldap" {
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

  group "openldap" {
    count = 1

    network {
      port "ldap" {
        static = 1389
      }
      port "ldaps" {
        static = 1636
      }
      mode = "host"
    }

    service {
      name     = "openldap"
      port     = "ldap"
      tags     = ["global", "tcp", "openldap"]
      provider = "consul"

      check {
        type     = "tcp"
        port     = "ldap"
        interval = "30s"
        timeout  = "20s"

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

    ephemeral_disk {
      size = 300
    }

    task "openldap" {
      driver = "docker"

      config {
        image        = "bitnami/openldap:latest"
        network_mode = "host"
        ports        = ["ldap", "ldaps"]
        auth_soft_fail = true
        volumes = [
          "/opt/openldap/ldifs:/ldifs"
        ]
      }

      resources {
        cpu        = 100
        memory     = 1024 # 1GB
      }

      env {
        LDAP_ROOT           = "dc=netlobo,dc=com"
        LDAP_ADMIN_USERNAME = "netlobo"
        LDAP_ADMIN_PASSWORD = "n!FCeqFeC_CqY4mPkiL"
        #LDAP_USERS = "ckm,appteam"
        #LDAP_PASSWORDS = "test123,test123"
        #LDAP_GROUP = "normalusers"
      }
    }
  }
}
