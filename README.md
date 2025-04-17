# NixOS Server Configuration

This repository contains the NixOS configuration for the `nix01` server, a Hyper-V virtual machine running NixOS with encrypted storage.

## System Overview

- **Hostname**: nix01
- **Base OS**: NixOS 24.11 (Vicuna)
- **Architecture**: x86_64-linux
- **Virtualization**: Hyper-V guest

## Disk Configuration (UEFI / Generation 2)

- **Disk**: /dev/sda (200 GiB)
- **Partitions**:
  1. /dev/sda1: 512 MB EFI System Partition (FAT32, type "EFI System")
  2. /dev/sda2: 199.5 GB LVM partition (LUKS encrypted)
- **Logical Volumes**:
  - Swap: 8 GiB
  - Root: 191.49 GiB

> **Note:** These instructions are for Hyper-V Generation 2 (UEFI) VMs. Ensure Secure Boot is **disabled** in the VM settings.

## Setup Instructions

### 1. Partitioning and Encryption (UEFI)

```bash
# Create GPT partition table
parted /dev/sda -- mklabel gpt

# Create EFI System Partition (ESP) - 512MiB, FAT32
parted /dev/sda -- mkpart ESP fat32 1MiB 513MiB
parted /dev/sda -- set 1 esp on

# Create LVM partition (rest of disk)
parted /dev/sda -- mkpart primary 513MiB 100%

# Format EFI partition
mkfs.fat -F32 -n EFI /dev/sda1

# Set up encryption
cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptlvm

# Set up LVM
pvcreate /dev/mapper/cryptlvm
vgcreate vg0 /dev/mapper/cryptlvm
lvcreate -L 8G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root

# Format partitions
mkfs.ext4 -L root /dev/mapper/vg0-root
mkswap -L swap /dev/mapper/vg0-swap
```

### 2. Installation

```bash
# Mount partitions
mount /dev/mapper/vg0-root /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot  # ESP mounted at /mnt/boot
swapon /dev/mapper/vg0-swap

# Generate initial configuration
nixos-generate-config --root /mnt

# (Important) Remove the generated config directory to avoid git clone errors
rm -rf /mnt/etc/nixos

# Install Git if not available in the installer environment
nix-env -iA nixos.git

# Clone the configuration repository
git clone https://github.com/ingolevin/nix-configs.git /mnt/etc/nixos/

# Install NixOS
nixos-install --flake /mnt/etc/nixos#nix01

# Enter the new system (if needed for troubleshooting)
nixos-enter --root /mnt

# Install GRUB for UEFI
# (If not done automatically by nixos-install, or if troubleshooting)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=NixOS

# Regenerate GRUB config
nixos-rebuild boot --flake /etc/nixos#nix01

# Reboot
reboot
```

### 3. Post-Installation

After booting into the installed system:

```bash
# Update the system
sudo nixos-rebuild switch --flake /etc/nixos#nix01

# Check system status
systemctl status
```

## Cloning the Repository

To clone this repository on a new system:

```bash
git clone https://github.com/ingolevin/nix-configs.git
```

## Configuration Structure

```
/etc/nixos/
├── flake.nix
├── configuration.nix
├── hardware-configuration.nix
├── modules/
│   ├── base.nix
│   ├── users.nix
│   ├── networking.nix
│   └── hyperv-guest.nix
└── home-manager/
    ├── default.nix
    ├── programs/
    │   └── default.nix
    └── users/
        └── stark84.nix
```

## User Configuration

- **Username**: stark84
- **SSH Authentication**: Key-based, no password
- **Groups**: wheel, networkmanager

## Troubleshooting Boot Issues

If you encounter boot issues:

1. Boot from the NixOS installation media
2. Unlock the encrypted partition:
   ```bash
   cryptsetup luksOpen /dev/sda2 cryptlvm
   ```
3. Mount the partitions:
   ```bash
   mount /dev/mapper/vg0-root /mnt
   mount /dev/sda1 /mnt/boot
   ```
4. Chroot into the installed system:
   ```bash
   nixos-enter --root /mnt
   ```
5. Reinstall GRUB:
   ```bash
   grub-install --target=i386-pc /dev/sda
   grub-mkconfig -o /boot/grub/grub.cfg
   ```
6. Rebuild the system:
   ```bash
   nixos-rebuild boot --flake /etc/nixos#nix01
   ```
7. Reboot:
   ```bash
   exit
   reboot
   ```
