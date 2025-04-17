{ config, pkgs, ... }:

{
  imports = [
    ../default.nix
  ];
  
  # Additional user-specific configurations
  programs.git = {
    enable = true;
    userName = "stark84";
    userEmail = "no-reply@github.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
  
  # Additional packages for this user
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    bat
    eza
    fzf
  ];
}
