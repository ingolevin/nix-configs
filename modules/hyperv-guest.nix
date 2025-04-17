{ config, pkgs, ... }:

{
  # Enable Hyper-V guest support
  virtualisation.hypervGuest.enable = true;
  

  # Enable video driver
  services.xserver.videoDrivers = [ "hyperv_fb" ];
}
