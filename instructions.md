# NixOS Configuration Guide for LLM Agents

This guide provides instructions for an LLM agent to configure a NixOS system. It includes documentation of the existing disk setup and best practices for Nix configurations.

## Part 1: Existing Disk Setup

The following disk setup has already been completed on the remote server:

### Disk Partitioning

The server has a 200 GiB virtual disk (`/dev/sda`) with the following partition layout:

```
Disk /dev/sda: 200 GiB, 214748364800 bytes, 419430400 sectors
Disk model: Virtual Disk    
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: dos
Disk identifier: 0xc0e2645f

Device     Boot   Start       End   Sectors   Size Id Type
/dev/sda1          2048   1026047   1024000   500M 83 Linux
/dev/sda2       1026048 419430399 418404352 199.5G 8e Linux LVM
```

- `/dev/sda1`: 500 MB boot partition
- `/dev/sda2`: 199.5 GB LVM partition (encrypted with LUKS)

### Encryption, LVM, and Filesystem Setup

The following steps were executed to set up disk encryption, LVM, and filesystems:

1. **LUKS Encryption Setup**:
   ```bash
   cryptsetup luksFormat /dev/sda2
   cryptsetup luksOpen /dev/sda2 enc-pv
   ```

2. **LVM Configuration**:
   ```bash
   pvcreate /dev/mapper/enc-pv
   vgcreate vg0 /dev/mapper/enc-pv
   lvcreate -L 8G -n swap vg0
   lvcreate -l '100%FREE' -n root vg0
   ```

3. **Filesystem Creation**:
   ```bash
   mkfs.ext4 -L boot /dev/sda1
   mkfs.ext4 -L nixos /dev/mapper/vg0-root
   mkswap -L swap /dev/mapper/vg0-swap
   ```

4. **Mounting Filesystems**:
   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mkdir /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   swapon /dev/disk/by-label/swap
   ```

The resulting logical volumes are:
- `/dev/mapper/vg0-swap`: 8 GiB swap partition
- `/dev/mapper/vg0-root`: 191.49 GiB root partition

## Part 2: NixOS Configuration Best Practices

### Initial Setup

1. **Generate the initial configuration**:
   ```bash
   nixos-generate-config --root /mnt
   ```

2. **Navigate to the configuration directory**:
   ```bash
   cd /mnt/etc/nixos
   ```

### Core Configuration Structure

Create a modular configuration structure:

```
/mnt/etc/nixos/
├── configuration.nix
├── hardware-configuration.nix
├── modules/
│   ├── base.nix
│   ├── users.nix
│   ├── networking.nix
│   ├── hyperv-guest.nix
│   └── ...
├── home-manager/
│   ├── default.nix
│   ├── programs/
│   │   └── ...
│   └── users/
│       └── ...
└── flake.nix
```

### Setting Up Flakes

1. **Create a `flake.nix` file**:

```nix
{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nix01 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.stark84 = import ./home-manager/users/stark84.nix;
        }
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
```

2. **Update `configuration.nix`**:

```nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/hyperv-guest.nix
  ];

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System settings
  system.stateVersion = "23.11"; # Update to match your NixOS version
}
```

### Hyper-V Guest Module

Create a file at `/mnt/etc/nixos/modules/hyperv-guest.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    "${pkgs.path}/nixos/modules/virtualisation/hyperv-guest.nix"
  ];

  # Additional Hyper-V specific configurations
  virtualisation.hypervGuest = {
    enable = true;
    videoMode = "1920x1080";
  };
}
```

### LUKS and Boot Configuration

Update the `hardware-configuration.nix` file to include the LUKS encryption setup:

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices = {
    "enc-pv" = {
      device = "/dev/disk/by-uuid/UUID_OF_SDA2"; # Replace with actual UUID
      preLVM = true;
      allowDiscards = true;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "ext4";
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  # Enable SSD TRIM
  services.fstrim.enable = true;
}
```

### Setting Up Home Manager

1. **Create a base home-manager configuration**:

Create `/mnt/etc/nixos/home-manager/default.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./programs
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "stark84"; # Replace with actual username
  home.homeDirectory = "/home/stark84"; # Replace with actual home directory

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "23.11"; # Update to match your NixOS version

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
```

2. **Create a user-specific configuration**:

Create `/mnt/etc/nixos/home-manager/users/stark84.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../default.nix
  ];

  # User-specific configurations
  programs.git = {
    enable = true;
    userName = "stark84";
    userEmail = "no-reply@github.com";
  };

  # Add more user-specific configurations here
}
```

### Base System Configuration

Create `/mnt/etc/nixos/modules/base.nix`:

```nix
{ config, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "Europe/Berlin"; # Adjust to your timezone

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
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

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
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
    flake = "/etc/nixos";
    flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Nix store optimization
  nix.settings.auto-optimise-store = true;
}
```

### User Configuration

Create `/mnt/etc/nixos/modules/users.nix`:

```nix
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
```

### Networking Configuration

Create `/mnt/etc/nixos/modules/networking.nix`:

```nix
{ config, pkgs, ... }:

{
  # Networking configuration
  networking = {
    hostName = "nix01"; # Define your hostname
    networkmanager.enable = true;
    
    # Configure firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      # Add more ports as needed
    };
  };
}
```

### Installation and Activation

After setting up all configuration files:

1. **Install NixOS**:
   ```bash
   nixos-install --flake /mnt/etc/nixos#nix01
   ```

2. **Reboot the system**:
   ```bash
   reboot
   ```

3. **After reboot, update the system**:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#nix01
   ```

### Best Practices for Ongoing Maintenance

1. **Keep your system up to date**:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#nix01 --update-input nixpkgs
   ```

2. **Test configuration changes before applying**:
   ```bash
   sudo nixos-rebuild test --flake /etc/nixos#nix01
   ```

3. **Roll back to a previous generation if needed**:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#nix01 --rollback
   ```

4. **Use Git to track configuration changes**:
   ```bash
   cd /etc/nixos
   git init
   git add .
   git commit -m "Initial NixOS configuration"
   ```

5. **Create a separate branch for experimental changes**:
   ```bash
   git checkout -b experimental
   # Make changes, test, and if satisfied:
   git checkout main
   git merge experimental
   ```

By following these instructions, you'll have a well-structured NixOS system with encrypted storage, home-manager integration, and Hyper-V guest support.
