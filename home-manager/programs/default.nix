{ config, pkgs, ... }:

{
  # Define common program configurations
  programs = {
    # Git configuration
    git = {
      enable = true;
      userName = "stark84";
      userEmail = "no-reply@github.com";
    };
    
    # Bash configuration
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        update = "sudo nixos-rebuild switch --flake /etc/nixos#nix01";
      };
    };
    
    # Vim configuration
    vim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
