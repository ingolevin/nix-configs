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

  # Enable bitcoind from upstream nix-bitcoin
  services.bitcoind = {
    enable = true;
    implementation = "knots";
    prune = 10000;
  };


  # Boot loader configuration
  boot.loader.systemd-boot = { enable = true; };

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System settings
  system.stateVersion = "24.11"; # Using the current NixOS version
}
