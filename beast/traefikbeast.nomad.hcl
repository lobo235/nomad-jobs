job "traefikbeast" {
    datacenters = ["pondside"]
    type        = "service"
    node_pool   = "beast"

    group "traefik" {
        network {
            mode = "host"
            port "web" {
                static = 80
            }
            port "websecure" {
                static = 443
            }
            port "api" {
                static = 8080
            }
            port "tcp" {
                static = 8008
            }
        }

        service {
            name = "traefik"
            port = "web"
            provider = "consul"

            check {
                type     = "http"
                path     = "/ping"
                port     = "web"
                interval = "10s"
                timeout  = "2s"
            }
        }

        service {
            name = "api"
            port = "api"
            provider = "consul"
            tags = [
                "traefik.http.routers.api.rule=Host(`traefik.big.netlobo.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))",
                "traefik.http.routers.api.service=api@internal",
                "traefik.http.routers.api.entrypoints=traefik"
            ]

#            check {
#                type     = "http"
#                path     = "/dashboard/"
#                protocol = "https"
#                tls_server_name = "traefik.big.netlobo.com"
#                port     = "api"
#                interval = "10s"
#                timeout  = "2s"
#            }
        }

        task "traefik" {
            driver = "docker"

            config {
                image        = "traefik:latest"
                network_mode = "host"
                ports        = ["web", "websecure", "api", "tcp"]
                auth_soft_fail = true
                volumes = [
                    "local/traefik.yaml:/etc/traefik/traefik.yaml",
                    "/mnt/fast/certs/big.netlobo.com/fullchain.pem:/opt/certs/big.netlobo.com/fullchain.pem",
                    "/mnt/fast/certs/big.netlobo.com/privkey.pem:/opt/certs/big.netlobo.com/privkey.pem"
                ]
            }

            template {
                data = <<EOF
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  tcp:
    address: ":8008"
  mariadb:
    address: ":3306"

ping:
  entryPoint: "web"

api:
  dashboard: true
  insecure: true
  debug: true

accessLog:
  filePath: "/local/access.log"

log:
  filePath: "/local/traefik.log"
  format: json
  level: DEBUG

tls:
  certificates:
    - certFile: /opt/certs/big.netlobo.com/fullchain.pem
      keyFile: /opt/certs/big.netlobo.com/privkey.pem
      stores:
        - default
  stores:
    default:
      defaultCertificate:
        certFile: /opt/certs/big.netlobo.com/fullchain.pem
        keyFile: /opt/certs/big.netlobo.com/privkey.pem

serversTransport:
  insecureSkipVerify: true

providers:
  file:
    filename: /local/traefik.yaml
    watch: true
  consulCatalog:
    prefix: "traefik"
    exposedByDefault: false
    endpoint:
      address: http://{{ env "NOMAD_IP_web" }}:8500
      scheme: "http"
      token: "{{ with nomadVar "nomad/jobs/traefikbeast" }}{{ .consul_token }}{{ end }}"
EOF
                destination = "local/traefik.yaml"
            }

            resources {
                cpu    = 2000
                memory = 4096 # 4GB
            }
        }
    }
}