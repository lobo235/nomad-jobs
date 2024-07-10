job "nginx" {
  node_pool = "hashi"
  datacenters = ["pondside"]
  type = "system"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "nginx" {
    count = 1

    network {
      mode = "bridge"
      port "nginx" {
        to = 80
      }
      port "nginx-secure" {
        to = 443
      }
    }

    service {
      name     = "nginx"
      port     = "nginx"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.nginx.rule=Host(`big.netlobo.com`)",
        "traefik.http.routers.nginx.entrypoints=web"
      ]

      check {
        type = "http"
        path = "/health"
        port = "nginx"
        interval = "30s"
        timeout = "20s"

        check_restart {
          limit = 3
          grace = "2m"
        }
      }
    }

    service {
      name     = "nginx-secure"
      port     = "nginx-secure"
      provider = "consul"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.nginx-secure.rule=Host(`big.netlobo.com`)",
        "traefik.http.routers.nginx-secure.entrypoints=websecure",
        "traefik.http.routers.nginx-secure.tls=true",
        "traefik.http.services.nginx-secure.loadbalancer.server.scheme=https"
      ]

      check {
        type = "http"
        protocol = "https"
        tls_server_name = "big.netlobo.com"
        path = "/health"
        port = "nginx-secure"
        interval = "30s"
        timeout = "20s"

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

    volume "certs" {
      type      = "host"
      read_only = true
      source    = "certs"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "linuxserver/nginx:latest"
        ports = ["nginx", "nginx_secure"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/nginx/config:/config",
          "local/scripts:/custom-cont-init.d"
        ]
      }

      volume_mount {
        volume      = "certs"
        destination = "/certs"
        read_only   = true
      }

      template {
        data = <<EOF
## Version 2023/04/13 - Changelog: https://github.com/linuxserver/docker-baseimage-alpine-nginx/commits/master/root/defaults/nginx/site-confs/default.conf.sample

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name big.netlobo.com;

    set $root /app/www/public;
    if (!-d /app/www/public) {
        set $root /config/www;
    }
    root $root;
    index index.html index.htm index.php;

    location / {
        # enable for basic auth
        #auth_basic "Restricted";
        #auth_basic_user_file /config/nginx/.htpasswd;

        try_files $uri $uri/ /index.html /index.php$is_args$args =404;
    }

    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }

    # deny access to .htaccess/.htpasswd files
    location ~ /\.ht {
        deny all;
    }

    location /health {
        access_log off;
        add_header 'Content-Type' 'application/json';
        return 200 '{"status":"UP"}';
    }
}
EOF
        destination = "local/default.conf"
      }

      template {
        data = <<EOF
server {
        listen 443 ssl http2;
        server_name big.netlobo.com;

        include /config/nginx/ssl.conf;

        set $plex http://10.77.3.9:32400;

        gzip on;
        gzip_vary on;
        gzip_min_length 1000;
        gzip_proxied any;
        gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
        gzip_disable "MSIE [1-6]\.";

        # Forward real ip and host to Plex
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        #When using ngx_http_realip_module change $proxy_add_x_forwarded_for to '$http_x_forwarded_for,$realip_remote_addr'
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
        proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
        proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;

        # Websockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";

        # Buffering off send to the client as soon as the data is received from Plex.
        proxy_redirect off;
        proxy_buffering off;
        
        location /health {
          access_log off;
          add_header 'Content-Type' 'application/json';
          return 200 '{"status":"UP"}';
        }

        location / {
            proxy_pass $plex;
        }
}
EOF
        destination = "local/revplex.conf"
      }

      template {
        data = <<EOF
## Version 2023/08/13 - Changelog: https://github.com/linuxserver/docker-baseimage-alpine-nginx/commits/master/root/defaults/nginx/ssl.conf.sample

### Mozilla Recommendations
# generated 2023-06-25, Mozilla Guideline v5.7, nginx 1.24.0, OpenSSL 3.1.1, intermediate configuration
# https://ssl-config.mozilla.org/#server=nginx&version=1.24.0&config=intermediate&openssl=3.1.1&guideline=5.7

ssl_certificate /certs/big.netlobo.com/fullchain.pem;
ssl_certificate_key /certs/big.netlobo.com/privkey.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m; # about 40000 sessions
ssl_session_tickets off;

# curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
ssl_dhparam /config/nginx/dhparams.pem;

# intermediate configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;

# HSTS (ngx_http_headers_module is required) (63072000 seconds)
#add_header Strict-Transport-Security "max-age=63072000" always;

# OCSP stapling
#ssl_stapling on;
#ssl_stapling_verify on;

# verify chain of trust of OCSP response using Root CA and Intermediate certs
#ssl_trusted_certificate /config/keys/cert.crt;

# Optional additional headers
#add_header Cache-Control "no-transform" always;
#add_header Content-Security-Policy "upgrade-insecure-requests; frame-ancestors 'self'" always;
#add_header Permissions-Policy "interest-cohort=()" always;
#add_header Referrer-Policy "same-origin" always;
#add_header X-Content-Type-Options "nosniff" always;
#add_header X-Frame-Options "SAMEORIGIN" always;
#add_header X-UA-Compatible "IE=Edge" always;
#add_header X-XSS-Protection "1; mode=block" always;
EOF
        destination = "local/ssl.conf"
      }

      template {
        data = <<EOF
#!/bin/bash
cp /local/default.conf /config/nginx/site-confs/default.conf
cp /local/ssl.conf /config/nginx/ssl.conf
cp /local/revplex.conf /config/nginx/site-confs/revplex.conf
EOF
        uid = 1
        gid = 0
        perms = "770"
        destination = "local/scripts/nginx-custom-config.sh"
      }

      resources {
        cpu        = 2000
        memory     = 256  # 256MB
      }

      env {
        PUID = 33
        PGID = 33
        TZ = "America/Denver"
        UMASK = "022"
      }
    }
  }
}
