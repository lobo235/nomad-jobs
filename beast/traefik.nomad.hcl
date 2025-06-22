job "traefik" {
  datacenters = ["pondside"]
  type        = "system"
  node_pool   = "beast"

  group "traefik" {
    
    update {
      max_parallel     = 1
      min_healthy_time = "10s"
      healthy_deadline = "2m"
      progress_deadline = "5m"
      auto_revert      = true
      canary           = 0
    }
    vault {
      cluster     = "default"
      change_mode = "noop"
    }

    network {
      mode = "host"
      port "web" {
        static = 81
      }
      port "websecure" {
        static = 444
      }
    }

    service {
      name     = "traefik"
      port     = "web"
      provider = "consul"

      check {
        type     = "http"
        path     = "/ping"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image          = "traefik:latest"
        network_mode   = "host"
        ports          = ["web", "websecure"]
        auth_soft_fail = true
        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
          "/mnt/fast/certs/big.netlobo.com/fullchain.pem:/opt/certs/big.netlobo.com/fullchain.pem",
          "/mnt/fast/certs/big.netlobo.com/privkey.pem:/opt/certs/big.netlobo.com/privkey.pem"
        ]
      }

      env {
        node_fqdn = "${node.unique.name}.big.netlobo.com"
      }

      # Traefik configuration template
      template {
        data = <<EOF
entryPoints:
  web:
    address: ":81"
  websecure:
    address: ":444"
    transport:
      respondingTimeouts:
        readTimeout: 600
  mariadb:
    address: ":3306"

ping:
  entryPoint: "web"
  manualRouting: true

api:
  dashboard: true
  debug: true
  insecure: false

http:
  routers:
    traefik:
      rule: "Host(`{{ env "node_fqdn" }}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
      entryPoints:
        - websecure
      service: api@internal
      tls: true
    ping:
      rule: "Path(`/ping`)"
      entryPoints:
        - web
      service: ping@internal

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

      token: "{{ with secret "kv/nomad/default/traefik" }}{{ .Data.data.consul_token }}{{ end }}"
EOF
        destination = "local/traefik.yaml"
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}
