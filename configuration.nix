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

  # Enable bitcoinknots from nix-bitcoin fork
  services.nix-bitcoin.bitcoinknots.enable = true;
  services.nix-bitcoin.bitcoind.enable = false;

  # Prune blockchain data, keep only ~75GB
  services.nix-bitcoin.bitcoinknots.extraConfig = ''
    prune=75000
  '';




  # Boot loader configuration
  boot.loader.systemd-boot = { enable = true; };

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System settings
  system.stateVersion = "24.11"; # Using the current NixOS version
}
