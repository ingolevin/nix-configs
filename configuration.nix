{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/hyperv-guest.nix
  ];

  # Define disko config inline
  disko.config = {
    devices = {
      disk.main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = [
            {
              name = "ESP";
              start = "1MiB";
              end = "513MiB";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            }
            {
              name = "luks";
              start = "513MiB";
              end = "100%";
              content = {
                type = "luks";
                name = "cryptlvm";
                content = {
                  type = "lvm";
                  lvs = [
                    {
                      name = "swap";
                      size = "8G";
                      content = {
                        type = "swap";
                        resumeDevice = true;
                      };
                    }
                    {
                      name = "root";
                      size = "100%FREE";
                      content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                      };
                    }
                  ];
                };
              };
            }
          ];
        };
      };
    };
  };

  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;
  };

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System settings
  system.stateVersion = "24.11"; # Using the current NixOS version
}
