variable "privkey" {
  type = string
  default = ""
}

variable "cert" {
    type = string
    default = ""
}

variable "consul_token" {
    type = string
    default = ""
}

job "traefik-consul" {
 node_pool = "beast"
 type        = "service"
 datacenters = ["pondside"]
 
 group "svc" {
   update {
     auto_revert = true
   }
   network {
     mode = "host"
 
     port "http" {
       to     = 80
       static = 80
     }
 
     port "https" {
       to     = 443
       static = 443
     }
 
     port "api" {
       to     = 8080
       static = 8080
     }
 
     port "metrics" {
       to     = 8082
       static = 8082
     }
   }
 
   service {
     tags = [
       "traefik",
       "traefik.enable=true",
       "traefik.http.routers.dashboard.rule=Host(`traefik.big.netlobo.com`)",
       "traefik.http.routers.dashboard.service=api@internal",
       "traefik.http.routers.dashboard.entrypoints=web,websecure",
     ]
 
     port = "http"
 
     check {
       type     = "http"
       port     = "api"
       path     = "/ping"
       interval = "10s"
       timeout  = "5s"
     }
   }
 
   service {
     tags = ["lb", "exporter"]
     port = "metrics"
 
     check {
       type     = "tcp"
       interval = "10s"
       timeout  = "5s"
     }
   }
 
   service {
     tags = ["lb", "api"]
     port = "api"
 
     check {
       type     = "http"
       path     = "/ping"
       interval = "10s"
       timeout  = "5s"
     }
   }
 
   task "loadbalancer" {
     driver = "docker"
 
     config {
       network_mode = "host"
       command      = "traefik"
       args         = ["--configFile", "/local/Traefik.yml"]
       image        = "traefik:latest"
       ports        = ["http", "https", "api", "metrics"]
     }
     template {
       data        = <<EOH
tls:
 certificates:
   - certFile: /local/lb.crt
     keyFile: /local/lb.key
 stores:
   default:
     defaultCertificate:
       certFile: /local/lb.crt
       keyFile: /local/lb.key
EOH
       destination = "/local/dynamic.yml"
       change_mode = "restart"
       splay       = "1m"
     }
 
    
     template {
       data        = <<EOH
{{ with nomadVar "nomad/jobs/traefik-consul" }}{{ .privkey }}{{ end }}
EOH
       destination = "/local/lb.key"
       change_mode = "restart"
       splay       = "1m"
     }
     template {
       data        = <<EOH
{{ with nomadVar "nomad/jobs/traefik-consul" }}{{ .cert }}{{ end }}
 EOH
       destination = "/local/lb.crt"
       change_mode = "restart"
       splay       = "1m"
     }
 
 
     template {
       data = <<EOH
CONSUL_HTTP_TOKEN={{ with nomadVar "nomad/jobs" }}{{ .consul_token }}{{ end }}
EOH
 
       env         = true
       destination = "secrets/traefik.env"
       change_mode = "noop"
     }
 
     template {
       data = <<EOH
serversTransport:
 insecureSkipVerify: true
entryPoints:
 web:
   address: ":80"
 websecure:
   address: ":443"
 api:
   address: ":8080"
 metrics:
   address: ":8082"
api:
 dashboard: true
 insecure: true
 debug: true
ping: {}
accessLog: {}
log:
 level: DEBUG
metrics:
 prometheus:
   entryPoint: metrics 
providers:
 providersThrottleDuration: 15s
 file:
   watch: true
   filename: "/local/dynamic.yml"
 consulCatalog:
   endpoint:
     scheme: http
     address: http://{{ env "NOMAD_IP_http" }}:8500
     token: {{ with nomadVar "nomad/jobs" }}{{ .consul_token }}{{ end }}
   cache: true
   prefix: traefik
   exposedByDefault: false
 EOH
 
       destination = "local/traefik.yml"
       change_mode = "noop"
     }
 
     resources {
       cpu = 500
       memory = 128
     }
   }
 }
}