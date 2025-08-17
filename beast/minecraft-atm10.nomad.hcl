job "mc-atm10" {
  node_pool  = "beast"
  datacenters = ["pondside"]
  type        = "service"

  group "mc-atm10" {
    count = 1

    network {
      port "minecraft" {
        to = 25565
      }
    }

    service {
      name     = "minecraft"
      tags     = ["global", "minecraft", "tcp", "atm10", "mc-router-register"]
      port     = "minecraft"
      provider = "consul"
      meta {
        mc-router-register = "true"
        externalServerName = "atm10.big.netlobo.com"
      }

      check {
        name     = "alive"
        type     = "tcp"
        interval = "30s"
        timeout  = "5s"
      }
    }

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    vault {
      cluster      = "default"
      change_mode  = "noop"
    }

    task "mc-atm10" {
      driver = "docker"

      config {
        image = "itzg/minecraft-server"
        entrypoint = ["/local/entrypoint.sh"]
        ports = ["minecraft"]
        auth_soft_fail = true
        volumes = [
          "/mnt/fast/minecraft/atm10/data:/data",
          "/mnt/fast/minecraft/atm10/modpacks:/modpacks",
          "/mnt/fast/minecraft/atm10/mods:/mods",
          "/mnt/fast/minecraft/atm10/downloads:/downloads:ro",
          "/mnt/fast/minecraft/atm10/config:/config",
          "/mnt/fast/minecraft/atm10/plugins:/plugins"
        ]
      }

      resources {
        cpu    = 21000
        memory = 9216
      }

      artifact {
        source      = "https://raw.githubusercontent.com/lobo235/nomad-jobs/refs/heads/main/beast/artifacts/atm10-start-custom.sh"
        options {
          filename  = "start-custom.sh"
        }
      }

      artifact {
        source      = "https://raw.githubusercontent.com/lobo235/nomad-jobs/refs/heads/main/beast/artifacts/atm10-restore-backup.sh"
        options {
          filename  = "restore-backup.sh"
        }
      }

      template {
        data = <<EOF
#!/bin/sh
chmod +x /local/start-custom.sh
chmod +x /local/restore-backup.sh
exec /local/start-custom.sh
EOF
        destination = "local/entrypoint.sh"
        perms       = "0755"
      }

      kill_timeout = "120s"

      meta {
        PACKVERSION      = "4.2"
        ATM_PACK_TYPE    = "ATM10"
        NEOFORGE_VERSION = "21.1.185"
      }

      env {
        MAINTENANCE_MODE         = "false"
        EULA                     = "TRUE"
        ENABLE_RCON              = "TRUE"
        RCON_PASSWORD            = "yourStrongPasswordHere"
        UID                      = 1001
        GID                      = 1001
        TZ                       = "America/Denver"
        SERVER_NAME              = "§f-§8=§cB§ba§er§al§9o§6w §dC§cr§ba§ef§at§8=§f- §aATM10 v${NOMAD_META_PACKVERSION}"
        MODE                     = "survival"
        DIFFICULTY              = "hard"
        ALLOW_FLIGHT            = "TRUE"
        ENABLE_COMMAND_BLOCK    = "TRUE"
        VIEW_DISTANCE           = 6
        MAX_PLAYERS             = 40
        SEED                    = "Barlow Craft - ATM10"
        OPS                     = "netlobo"
        MOTD                    = "\u00a7f-\u00a78=\u00a7cB\u00a7ba\u00a7er\u00a7al\u00a79o\u00a76w \u00a7dC\u00a7cr\u00a7ba\u00a7ef\u00a7at\u00a78=\u00a7f- \u00a7aATM10 v${NOMAD_META_PACKVERSION}"
        USE_CUSTOM_START_SCRIPT = "true"
        TYPE                    = "CUSTOM"
        CUSTOM_JAR_EXEC         = "@user_jvm_args.txt @libraries/net/neoforged/neoforge/${NOMAD_META_NEOFORGE_VERSION}/unix_args.txt nogui"
        VERSION                 = "1.21.1"
        PACKVERSION             = "${NOMAD_META_PACKVERSION}"
        INIT_MEMORY             = "4G"
        MAX_MEMORY              = "8G"
        MAX_WORLD_SIZE          = 16016
        MAX_TICK_TIME           = 180000
        COPY_CONFIG_DEST        = "/data/world/serverconfig"
        SYNC_SKIP_NEWER_IN_DESTINATION = "false"
      }
    }
    affinity {
      attribute = "${meta.fast_cpu}"
      value     = "true"
      weight    = 100
    }
  }
}
