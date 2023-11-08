job "traefikhashi" {
    datacenters = ["pondside"]
    node_pool   = "hashi"
    type        = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "hashi1"
  }

    group "traefik" {
        count = 1

        network {
            mode = "host"
            port "web" {
              static = 8888
            }
            port "websecure" {
              static = 8443
            }
            port "api" {
              static = 8080
            }
            port "dns" {
              static = 53
              host_network = "public"
            }
        }

        service {
            name = "traefikhashi"
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
                "traefikhashi.http.routers.api.rule=Host(`hashi1.big.netlobo.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))",
                "traefikhashi.http.routers.api.service=api@internal",
                "traefikhashi.http.routers.api.entrypoints=traefik"
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
                ports        = ["web", "websecure", "api", "dns"]
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
    address: ":8888"
  websecure:
    address: ":8443"
  dnstcp:
    address: "{{ env "NOMAD_IP_dns" }}:53/tcp"
  dnsudp:
    address: "{{ env "NOMAD_IP_dns" }}:53/udp"
    udp:
      timeout: 10s

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
    prefix: "traefikhashi"
    exposedByDefault: false
    endpoint:
      address: http://{{ env "NOMAD_IP_web" }}:8500
      scheme: "http"
      token: "{{ with nomadVar "nomad/jobs/traefikhashi1" }}{{ .consul_token }}{{ end }}"
EOF
                destination = "local/traefik.yaml"
            }

            resources {
                cores    = 1
                memory = 1024
            }
        }
    }
}