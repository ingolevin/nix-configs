{ config, pkgs, ... }:

{
  # Define a user account
  users.users.stark84 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable 'sudo' for the user
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIod8tCZMMsG3nkneJ7MBluFXE97iTXXMOn5gxbPm8s admin@dalinar" # Replace with your SSH public key
    ];
    # Don't set a password, use SSH key authentication
    hashedPassword = null;
  };

  # Enable sudo explicitly (secure-node disables it), and make it NOPASSWD for wheel
  security.sudo.enable = pkgs.lib.mkForce true;
  security.sudo.wheelNeedsPassword = pkgs.lib.mkForce false;

  # Keep doas too, NOPASSWD (optional, but consistent with secure-node)
  security.doas.enable = pkgs.lib.mkForce true;
  security.doas.wheelNeedsPassword = pkgs.lib.mkForce false;
}
