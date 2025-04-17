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

## Automated Setup Instructions (nixos-anywhere + disko)

This setup is now fully automated using [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) and [`disko`](https://github.com/nix-community/disko). Manual partitioning and encryption are no longer required.

### Prerequisites
- A Hyper-V Generation 2 (UEFI) VM with Secure Boot **disabled**
- Your VM's virtual disk attached and empty
- The VM is accessible via SSH (typically via the NixOS installer ISO, with networking configured)
- Another machine (your admin workstation) with Nix and `nixos-anywhere` installed

### 1. Boot the Target VM
- Boot the VM from the NixOS installer ISO
- Set a root password and ensure SSH is running:
  ```sh
  passwd
  systemctl start sshd
  ip a  # Find the VM's IP address
  ```

### 2. Run nixos-anywhere from your workstation
Install nixos-anywhere if you haven't:
```sh
nix profile install github:nix-community/nixos-anywhere
```
Run the installer (replace `<ip>` and `<ssh_config_alias>` as needed):
```sh
nixos-anywhere --flake github:ingolevin/nix-configs#nix01 root@<ip>|<ssh_config_alias>
```
or for a certain branch: 
```sh
nixos-anywhere --flake github:ingolevin/nix-configs?ref=<branch_name>#nix01 root@<ip>|<ssh_config_alias>
```

- This will use your flake and the declarative disk layout in `disko.nix` to partition, format, encrypt, and install NixOS, fully unattended.
- You will be prompted for the LUKS passphrase during the process.

### 3. Reboot and Use Your System
- Once complete, reboot the VM and remove the ISO.
- The system will boot into your fully configured NixOS environment.

### Troubleshooting
- Ensure Secure Boot is **disabled** in Hyper-V VM settings.
- If you encounter boot issues, verify that the disk is set as the first boot device and that the disk was wiped before install.
- For advanced troubleshooting, you can still boot the installer ISO and use `nixos-enter` as before.

### Summary
- All disk setup, encryption, and installation are now **fully automated** and reproducible.
- Your configuration is defined in `flake.nix` and `disko.nix`.
- To reinstall or deploy elsewhere, simply repeat the `nixos-anywhere` command.
mount /dev/mapper/vg0-root /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot  # ESP mounted at /mnt/boot
swapon /dev/mapper/vg0-swap

## Configuration Structure

```
/etc/nixos/
├── flake.nix
├── configuration.nix
├── hardware-configuration.nix
├── disko.nix
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

## Troubleshooting

- Ensure Secure Boot is **disabled** in Hyper-V VM settings.
- If the system fails to boot after install, double-check that you used the automated `nixos-anywhere` + `disko` workflow and that the disk was empty before install.
- For advanced troubleshooting, you can still boot the installer ISO and use `nixos-enter` to inspect the system, but manual partitioning and bootloader steps should not be necessary with the new workflow.
