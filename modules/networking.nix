{ config, pkgs, ... }:

{
  # Set hostname
  networking.hostName = "nix01";
  
  # Enable NetworkManager
  networking.networkmanager.enable = true;
  
  # Configure firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
  };
}
