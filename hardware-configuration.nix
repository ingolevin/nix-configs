{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ata_piix" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Enable LUKS encryption
  boot.initrd.luks.devices."cryptlvm" = {
    device = "/dev/sda2";
    preLVM = true;
    allowDiscards = true;
  };

  # Mount points
  fileSystems."/" = {
    device = "/dev/mapper/vg0-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/mapper/vg0-swap"; }
  ];

  # Hyper-V specific settings
  virtualisation.hypervGuest.enable = true;
}
