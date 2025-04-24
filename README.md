# NixOS Server Configuration

This repository contains the NixOS configuration for the `nix01` server, a Hyper-V Generation 2 virtual machine running NixOS with encrypted storage and fully declarative setup.

## System Overview

- **Hostname**: nix01
- **Base OS**: NixOS 24.11 (Vicuna)
- **Architecture**: x86_64-linux
- **Virtualization**: Hyper-V Generation 2 (UEFI, Secure Boot **disabled**)
- **Bootloader**: systemd-boot (UEFI only, robust for Hyper-V Gen2)

## Disk Configuration (Automated with Disko)

- **Disk**: /dev/sda (200 GiB)
- **Partitions**:
  1. /dev/sda1: 512 MB EFI System Partition (FAT32, type "EFI System")
  2. /dev/sda2: LUKS-encrypted partition (LVM inside)
- **Logical Volumes**:
  - Swap: 8 GiB
  - Root: remainder

> **Note:** Secure Boot must be **disabled** in Hyper-V settings. systemd-boot is used for UEFI booting (not GRUB).
> 
> **LUKS Passphrase:** Use a simple, all-lowercase, no-symbols passphrase for initial install to avoid keyboard layout issues. The initramfs may default to US QWERTY during setup.

## Automated Setup Instructions (nixos-anywhere + disko)

This setup is fully automated using [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) and [`disko`](https://github.com/nix-community/disko). Manual partitioning and encryption are not required.

### Prerequisites
- Hyper-V Gen2 VM, Secure Boot **disabled**, disk empty
- VM accessible via SSH (installer ISO, networking configured)
- Admin workstation with Nix and `nixos-anywhere` installed

### 1. Boot the Target VM
- Boot from the NixOS installer ISO
- Set a root password and start SSH:
  ```sh
  passwd
  systemctl start sshd
  ip a  # Find the VM's IP address
  ```

### 2. Run nixos-anywhere from your workstation
Install nixos-anywhere if needed:
```sh
nix profile install github:nix-community/nixos-anywhere
```
Run the installer (replace `<ip>` as needed):
```sh
nixos-anywhere --flake "github:ingolevin/nix-configs#nix01" root@<ip>
```
- This will partition, format, encrypt, and install NixOS as declared in your flake and Disko config.
- You will be prompted for the LUKS passphrase. **Type it carefully and use a simple passphrase to avoid layout confusion.**

### 3. Reboot and Use Your System
- Remove the ISO and reboot the VM.
- The system will boot into your fully configured NixOS environment.

### Routine Configuration Changes
- **Do NOT use `nixos-anywhere` for regular changes.**
- Instead:
  1. Edit your config locally and push to your git repo.
  2. SSH into the VM as `stark84` (see user config below).
  3. Pull the latest config inside the VM.
  4. Run:
     ```sh
     sudo nixos-rebuild switch --flake .#nix01
     ```
- This applies your changes without wiping the system.

### SSH User Access
- The default user is `stark84`, with key-based SSH authentication.
- Make sure your SSH public key is present in `modules/users.nix` under `openssh.authorizedKeys.keys`.
- Root SSH login is disabled by default. Use `sudo` after logging in as `stark84`.

### Hyper-V Dynamic Memory
- Dynamic memory is supported. Make sure to enable it in Hyper-V Manager on the host:
  - Shut down the VM
  - Run (on the host):
    ```powershell
    Set-VMMemory -VMName "nix-os" -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 4GB -MaximumBytes 16GB
    ```
  - Start the VM. The guest will report the "Assigned Memory" from Hyper-V.
- The `hv_balloon` driver is loaded automatically by `virtualisation.hypervGuest.enable = true;`.

### Troubleshooting
- If LUKS passphrase fails after install, it's likely a keyboard layout mismatch or typo. Reinstall with a simple passphrase if needed.
- If you can't SSH in, ensure your key matches the one in `modules/users.nix`.
- For advanced troubleshooting, boot the installer ISO and use `nixos-enter` as before.

### Summary
- All disk setup, encryption, and installation are **fully automated** and reproducible.
- Your configuration is defined in `flake.nix`, `disko-config.nix`, and the `modules/` directory.
- To reinstall or deploy elsewhere, repeat the `nixos-anywhere` command (this will wipe the disk).

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

- **Username**: `stark84`
- **SSH Authentication**: Key-based (see `modules/users.nix`)
- **Groups**: wheel, networkmanager
- **Root login**: Disabled over SSH; use `sudo` as `stark84`

## Configuration Structure

```
/etc/nixos/
├── flake.nix
├── configuration.nix
├── hardware-configuration.nix
├── disko-config.nix
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

## Development Workflow: Deploying Configuration Changes

After the initial setup with `nixos-anywhere`, you should NOT use it for routine configuration changes. Instead, use the following workflow:

1. **Edit your NixOS configuration locally** (on your development machine, e.g., in your git repo).
2. **Commit and push your changes** to your git repository (if using git).
3. **SSH into the VM** as your regular user (e.g., `stark84`).
4. **Pull the latest changes** from your git repository inside the VM.
5. **Apply the changes** with:
   ```sh
   sudo nixos-rebuild switch --flake .#nix01
   ```
   *(Replace `.#nix01` with your actual flake reference if different.)*

This will rebuild and activate your updated configuration without touching your data or reformatting the disk. This is the standard, safe way to make ongoing changes.

---

## Full Redeployment: Reinstalling from Scratch

If you want to **wipe the VM and redeploy the entire configuration from scratch** (for example, to start over or deploy to a new machine):

1. **Boot the target VM from the NixOS installer ISO** and ensure SSH is running.
2. **From your admin workstation, run:**
   ```sh
   nixos-anywhere --flake "github:ingolevin/nix-configs#nix01" root@<ip>
   ```
   *(Replace `<ip>` with the VM's IP address.)*

This will destroy all existing data on the VM's disk, repartition, re-encrypt, and redeploy everything as declared in your flake and Disko config. You will be prompted for the LUKS passphrase.

---

## Workflow Comparison

| Use Case                      | Command/Workflow                                      | Data Preserved? |
|-------------------------------|-------------------------------------------------------|-----------------|
| Routine config changes        | `nixos-rebuild switch --flake .#nix01`                | Yes             |
| Full reinstall/redeployment   | `nixos-anywhere --flake ... root@<ip>`                | No (disk wiped) |

- **Routine changes:** Use `nixos-rebuild` for updates, tweaks, and upgrades. This is safe and preserves your data.
- **Full redeploy:** Use `nixos-anywhere` only if you want to start from scratch or deploy to a new machine. This will wipe the disk and destroy all existing data!

---

## Troubleshooting

- Secure Boot **must be disabled** in Hyper-V for UEFI booting.
- If the system fails to boot, ensure you used the automated workflow and that the disk was empty before install.
- If you cannot unlock LUKS, try reinstalling with a simple passphrase.
- If you cannot SSH in, check that your public key matches the one in `modules/users.nix`.
- For advanced troubleshooting, boot the installer ISO and use `nixos-enter` to inspect the system.
