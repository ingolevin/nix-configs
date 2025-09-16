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
  programs.bash = {
    enable = true;
    shellAliases = {
      bitcoinlog = "sudo journalctl -fu bitcoind";
      bitcoinconf = "sudo nano /var/lib/bitcoind/bitcoin.conf";
      nix-rebuild = "sudo nixos-rebuild switch --flake '/etc/nixos/.#nix01'";
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
    btop
    infisical
  ];

home.sessionVariables = {


};
}
