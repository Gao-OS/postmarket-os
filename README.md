# postmarketOS Builder

Manage multiple postmarketOS device build environments with a single command. Built on NixOS devenv and pmbootstrap.

## Features

- Manage multiple device builds independently (like `nvm` for Node.js)
- Interactive device selection with fzf
- Isolated work directories per device
- Shared pmaports repository for all devices
- Simple pmbootstrap workflow wrapper

## Requirements

- NixOS or system with Nix installed
- devenv: `nix profile install nixpkgs#devenv`
- direnv (optional)

**NixOS users** must enable ARM emulation:

```nix
# configuration.nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
```

## Quick Start

```bash
devenv shell                    # Enter FHS environment
pmos new pine64-pinephone       # Create device
pmos init                       # Configure pmbootstrap
pmos build                      # Build image
pmos export                     # Export flashable image
pmos flash                      # Flash to device
```

## FHS Environment

This project uses `buildFHSEnv` to provide a standard Linux filesystem hierarchy. This ensures compatibility with pmbootstrap and other tools that expect traditional paths like `/usr/bin`.

**Automatic entry**: When you run `devenv shell` interactively, you automatically enter the FHS environment.

**Manual entry**: Use the `pmos-fhs` command to explicitly enter the FHS environment:

```bash
pmos-fhs                        # Enter FHS shell
pmos-fhs <command>              # Run command in FHS
```

**Inside FHS**:
- pmbootstrap is at `/usr/bin/pmbootstrap`
- All standard utilities available at expected paths
- Environment variables (`PMOS_DEVICES_DIR`, etc.) are inherited

## Workflow

### Step 1: Create Device Environment

```bash
pmos new <device-codename>      # e.g., pmos new oneplus-enchilada
```

Find device codenames at [postmarketOS Devices](https://wiki.postmarketos.org/wiki/Devices).

### Step 2: Initialize pmbootstrap

```bash
pmos init
```

This runs the interactive pmbootstrap configuration where you select:
- UI (Phosh, Plasma Mobile, GNOME, etc.)
- Username and hostname
- Additional packages

### Step 3: Build the Image

```bash
pmos build
```

This compiles the kernel, packages, and creates the root filesystem. Build time varies (30 min - 2+ hours depending on device and network).

### Step 4: Export or Flash

**Option A: Export image files**
```bash
pmos export
```
Creates flashable images in `out/<device>/`.

**Option B: Direct flash** (device connected via USB in fastboot mode)
```bash
pmos flash
```

## Directory Structure

```
postmarket-os/
├── devenv.nix              # Main configuration
├── pmaports/               # Shared pmaports repository (auto-cloned)
├── devices/                # Per-device work directories
│   └── <device>/
│       ├── chroot_native/           # Build chroot (x86_64)
│       ├── chroot_rootfs_<device>/  # Target rootfs (aarch64/armv7l)
│       ├── packages/                # Built APK packages
│       ├── cache_*/                 # Various caches
│       └── log.txt                  # Build log
└── out/                    # Exported images
    └── <device>/
        ├── <device>.img             # Root filesystem image
        └── boot.img                 # Boot image (kernel + initramfs)
```

## Commands

| Command | Description |
|---------|-------------|
| `pmos-fhs` | Enter FHS environment (auto on interactive shell) |
| `pmos new <device>` | Create device environment |
| `pmos use [device]` | Switch device (fzf selection if no argument) |
| `pmos list` | List all devices |
| `pmos current` | Show current device |
| `pmos rm <device>` | Remove device |
| `pmos init` | Initialize pmbootstrap |
| `pmos build` | Build system image |
| `pmos flash` | Flash rootfs and kernel |
| `pmos export` | Export image to `out/` |
| `pmos shell` | Enter device chroot |
| `pmos status` | View configuration |
| `pmos log` | View build logs |
| `pmos clean` | Clean build cache |
| `pmos clean --all` | Clean all caches |
| `pmos update` | Update pmaports repository |
| `pmos help` | Show help |

## Proxy Configuration

Edit `devenv.nix` and uncomment:

```nix
env = {
  HTTP_PROXY = "http://127.0.0.1:3128";
  HTTPS_PROXY = "http://127.0.0.1:3128";
};
```

## Troubleshooting

**Build fails with network errors**
```bash
pmos clean --all    # Clear corrupted cache
pmos build          # Retry
```

**Check build logs**
```bash
pmos log            # View recent log
pmos log -f         # Follow log in real-time
```

**Kernel config issues**
```bash
pmbootstrap kconfig check linux-postmarketos-<kernel>
```

## Notes

- Each device work directory uses ~5-10GB disk space
- Build requires network access to Alpine/postmarketOS repositories
- First build downloads ~2GB of packages (cached for subsequent builds)
- pmbootstrap chroot may have compatibility issues on some NixOS setups
- Use `pmos clean` to free space, `pmos clean --all` for full reset

## Resources

- [postmarketOS Wiki](https://wiki.postmarketos.org/)
- [Supported Devices](https://wiki.postmarketos.org/wiki/Devices)
- [pmbootstrap Documentation](https://wiki.postmarketos.org/wiki/Pmbootstrap)
- [devenv Documentation](https://devenv.sh/)
