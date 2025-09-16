{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/hyperv-guest.nix
    ./disko-config.nix

    # nix-bitcoin preset: secure-node
    (inputs.nix-bitcoin + "/modules/presets/secure-node.nix")
  ];

  # Configure nix-bitcoin
  nix-bitcoin.generateSecrets = true;
  nix-bitcoin.operator.name = "stark84";

  # Use nix-bitcoin's overlay so pkgs.bitcoin-knots (and other packages) come from the fork
  nixpkgs.overlays = [ inputs.nix-bitcoin.overlays.default ];

  # Enable bitcoin-knots from the fork by setting the implementation in services.bitcoind
  services.bitcoind = {
    enable = true;
    implementation = "knots";
    # Prune blockchain data, keep only ~10GB
    prune = 10000;
    rpc = {
      address = "0.0.0.0";          # or the machine’s LAN IP
      allowip = [ "192.168.10.0/24" "10.0.0.0/24"]; # allow LAN clients
      # users.<name>.passwordHMACFromFile is handled via secrets;
      # default users 'public' and 'privileged' are created by the module.
    };

    # Use knotsSpecificOptions as defined in the fork's module
    knotsSpecificOptions = {
      datacarriersize = 82;
      #blocknotify = "killall -USR1 datum_gateway";
    };
  };

/*
  # Datum gateway settings
  services.datum-gateway = {
  serviceConfig = {
    # Load secrets from Infisical-generated env file
    EnvironmentFile = "/run/infisical/datum-gateway.env";
  };
  preStart = ''
    infisical export --env=prod --format=dotenv > /run/infisical/datum-gateway.env
    chmod 600 /run/infisical/datum-gateway.env
  '';

    enable = true;
    settings = {
      mining = {
        # Bitcoin address used for mining rewards (REQUIRED)
        pool_address = "$DATUM_MINING_POOL_ADDRESS";
        # Primary coinbase tag (default: "DATUM Gateway (nix-bitcoin)")
        coinbase_tag_primary = "$DATUM_MINING_COINBASE_TAG_PRIMARY";
        # Secondary coinbase tag (default: "DATUM User")
        coinbase_tag_secondary = "$DATUM_MINING_COINBASE_TAG_SECONDARY";
        # Unique ID (1-65535) appended to coinbase (default: 4242)
        #coinbase_unique_id = "$DATUM_MINING_COINBASE_UNIQUE_ID";
        # Directory to save all submitted blocks as JSON (empty disables)
        #save_submitblocks_dir = "$DATUM_MINING_SAVE_SUBMITBLOCKS_DIR";
      };
      bitcoind = {
        # Path to file to read RPC cookie from (for local bitcoind authentication)
        rpccookiefile = "${config.services.bitcoind.dataDir}/.cookie";
        # RPC username for bitcoind (if not using cookie authentication)
        #rpcuser = "$DATUM_BITCOIND_RPCUSER";
        # RPC password for bitcoind (if not using cookie authentication)
        #rpcpassword = "$DATUM_BITCOIND_RPCPASSWORD";
        # RPC URL for communication with local bitcoind (REQUIRED)
        rpcurl = "http://localhost:8332";
        # Seconds between normal work updates (default: 40)
        #work_update_seconds = "$DATUM_BITCOIND_WORK_UPDATE_SECONDS";
        # Fallback to polling if blocknotify is not set up (default: true)
        notify_fallback = true;
      };
      stratum = {
        # Listen address for Stratum Gateway (default: "0.0.0.0")
        #listen_addr = "0.0.0.0";
        # Listening port for Stratum Gateway (default: 23334)
        listen_port = 23334;
        # Maximum clients per Stratum server thread (default: 128)
        #max_clients_per_thread = "$DATUM_STRATUM_MAX_CLIENTS_PER_THREAD";
        # Maximum Stratum server threads (default: 8)
        #max_threads = "$DATUM_STRATUM_MAX_THREADS";
        # Maximum total Stratum clients before rejecting connections (default: 1024)
        #max_clients = "$DATUM_STRATUM_MAX_CLIENTS";
        # Work difficulty floor (default: 16384)
        #vardiff_min = "$DATUM_STRATUM_VARDIFF_MIN";
        # Target shares per minute for variable difficulty (default: 8)
        #vardiff_target_shares_min = "$DATUM_STRATUM_VARDIFF_TARGET_SHARES_MIN";
        # Shares before considering a quick diff update (default: 8)
        # vardiff_quickdiff_count = "$DATUM_STRATUM_VARDIFF_QUICKDIFF_COUNT";
        # How much faster than target before enforcing quick diff bump (default: 8)
        #vardiff_quickdiff_delta = "$DATUM_STRATUM_VARDIFF_QUICKDIFF_DELTA";
        # Seconds after job is generated before a share is stale (default: 120)
        #share_stale_seconds = "$DATUM_STRATUM_SHARE_STALE_SECONDS";
        # Attempt to fingerprint miners for better use of coinbase space (default: true)
        #fingerprint_miners = "$DATUM_STRATUM_FINGERPRINT_MINERS";
        # Idle timeout without subscription (0 disables, default: 15)
        #idle_timeout_no_subscribe = "$DATUM_STRATUM_IDLE_TIMEOUT_NO_SUBSCRIBE";
        # Idle timeout without shares (0 disables, default: 7200)
        #idle_timeout_no_shares = "$DATUM_STRATUM_IDLE_TIMEOUT_NO_SHARES";
        # Idle timeout since last accepted share (0 disables, default: 0)
        #idle_timeout_max_last_work = "$DATUM_STRATUM_IDLE_TIMEOUT_MAX_LAST_WORK";
      };
      api = {
        # API password for dashboard (username 'admin'; set to something secure!)
        admin_password = "admin";
        listen_addr = "0.0.0.0";
        # Port to listen for API/dashboard requests (0 disables, default: 0)
        listen_port = 23335;
        # Enable modifying the config file from API/dashboard (default: false)
        modify_conf = false;
      };
      logger = {
        log_to_console = true;
        log_to_file = false;
        log_file = "/var/log/datum.log";
        log_rotate_daily = true;
        log_level_console = 2;
        log_level_file = 1;
      };
      datum = {
        # Remote DATUM server host/IP (default: "datum-beta1.mine.ocean.xyz")
        #host = "datum-beta1.mine.ocean.xyz";
        # Remote DATUM server port (default: 28915)
        #port = 28915;
        # Public key of the DATUM server for initiating encrypted connection
        #pubkey = "";
        # Pass stratum miner usernames as sub-worker names to the pool (default: true)
        pool_pass_workers = true;
        # Pass stratum miner usernames as raw usernames to the pool (default: false)
        pool_pass_full_users = true;
        # Always include my datum.pool_username payout in my blocks if possible (default: true)
        #always_pay_self = true;
        # If DATUM pool unavailable, terminate miner connections (default: true)
        pooled_mining_only = true;
        # Timeout for DATUM server messages in seconds (default: 60)
        #protocol_global_timeout = 60;
      };
    };
  };
*/

  # Boot loader configuration
  boot.loader.systemd-boot = { enable = true; };

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "local-1:HRAske2IsfnS12keRqYhLOPDd1PlWu3D7LtCQPbGfdY=" ];

  # System settings
  system.stateVersion = "24.11"; # Using the current NixOS version
}
