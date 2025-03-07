{ config, pkgs, ... }:

{
  imports = [
    ./programs
  ];
  
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "stark84";
  home.homeDirectory = "/home/stark84";
  
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";
  
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
