{ config, pkgs, ... }:

{
  # Enable Hyper-V guest support
  virtualisation.hypervGuest.enable = true;
  
  # Enable enhanced session mode if needed
  virtualisation.hypervGuest.enhancedSessionTransport = true;
  
  # Enable video driver
  services.xserver.videoDrivers = [ "hyperv_fb" ];
}
