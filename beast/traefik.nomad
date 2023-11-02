job "traefik" {
  node_pool = "beast"
  datacenters = ["pondside"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port  "http"{
         static = 80
      }
      port  "admin"{
         static = 8080
      }
    }

    service {
      name = "traefik-http"
      provider = "nomad"
      port = "http"

      check {
        type = "http"
        port = "admin"
        path = "/ping"
        interval = "10s"
        timeout = "2s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "traefik:latest"
        ports = ["admin", "http"]
        args = [
          "--ping",
          "--api.dashboard=true",
          "--api.insecure=true", ### For Test only, please do not use that in production
          "--entrypoints.web.address=:${NOMAD_PORT_http}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://10.77.3.7:4646", ### IP to your nomad server
          "--providers.nomad.endpoint.token=${NOMAD_TOKEN}",
        ]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.txt"
        env         = true
        data        = <<EOT
NOMAD_TOKEN={{ with nomadVar "nomad/jobs/traefik" }}{{ .nomad_token }}{{ end }}
EOT
      }
    }
  }
}