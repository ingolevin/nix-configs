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

  # Allow users in the wheel group to execute sudo commands without a password
  security.sudo.wheelNeedsPassword = false;
}
