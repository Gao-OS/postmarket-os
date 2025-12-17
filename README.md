# postmarketOS Builder

Manage multiple postmarketOS device build environments with a single command. Built on NixOS devenv and pmbootstrap.

## Features

- Manage multiple device builds independently (like `nvm` for Node.js)
- Interactive device selection with fzf
- Isolated work directories per device
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
devenv shell                    # Enter environment
pmos new pine64-pinephone       # Create device
pmos init                       # Configure pmbootstrap
pmos build                      # Build image
pmos flash                      # Flash to device
```

## Commands

| Command | Description |
|---------|-------------|
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
| `pmos help` | Show help |

## Proxy Configuration

Edit `devenv.nix` and uncomment:

```nix
env = {
  HTTP_PROXY = "http://127.0.0.1:3128";
  HTTPS_PROXY = "http://127.0.0.1:3128";
};
```

## Notes

- Each device work directory uses ~5-10GB disk space
- Build requires network access to Alpine repositories
- pmbootstrap chroot may have compatibility issues on some NixOS setups

## Resources

- [postmarketOS Wiki](https://wiki.postmarketos.org/)
- [Supported Devices](https://wiki.postmarketos.org/wiki/Devices)
- [pmbootstrap Documentation](https://wiki.postmarketos.org/wiki/Pmbootstrap)
- [devenv Documentation](https://devenv.sh/)
