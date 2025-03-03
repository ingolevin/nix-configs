{ config, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Configure console keymap
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
    tmux
    ripgrep
    fd
    jq
  ];

  # Enable automatic system upgrades
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize store
  nix.settings.auto-optimise-store = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
