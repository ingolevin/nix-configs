{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/hyperv-guest.nix
    ./disko-config.nix

  ];

  # Configure nix-bitcoin
  nix-bitcoin.generateSecrets = true;

  # Disable bitcoind from upstream nix-bitcoin
  services.bitcoind.enable = false;

  # Enable bitcoin-knots from the fork
  services.bitcoin-knots = {
    enable = true;
    # Prune blockchain data, keep only ~10GB
    # Use knotsSpecificOptions as defined in the fork's module
    knotsSpecificOptions = {
      prune = "10000";
    };
  };

  # Boot loader configuration
  boot.loader.systemd-boot = { enable = true; };

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System settings
  system.stateVersion = "24.11"; # Using the current NixOS version
}
