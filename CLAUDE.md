# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

postmarketOS Builder - a NixOS devenv-based tool for managing multiple postmarketOS device build environments via the `pmos` command (similar to how `nvm` manages Node.js versions).

## Development Commands

```bash
# Enter development environment
devenv shell

# Or with direnv
direnv allow

# Test the pmos command
pmos help
pmos new test-device
pmos list
pmos use test-device
pmos current
pmos rm test-device
```

## Architecture

All functionality is in `devenv.nix`:
- **env**: Environment variables (`PMOS_DEVICES_DIR`, `PMOS_CURRENT_FILE`, `PMOS_OUT_DIR`)
- **packages**: Dependencies (pmbootstrap, android-tools, qemu, fzf, git)
- **enterShell**: Welcome message shown on environment entry
- **scripts.pmos.exec**: The `pmos` command implementation as a bash case statement

The `pmos` command wraps pmbootstrap with device-specific work directories stored in `devices/<device-name>/`.

## Nix Shell Script Conventions

**Critical**: In Nix strings, use `''${var}` instead of `${var}` to prevent Nix interpretation:
```nix
cmd="''${1:-help}"  # Correct - bash variable
cmd="${1:-help}"    # Wrong - Nix tries to interpolate
```

Helper functions use `_` prefix: `_get_current()`, `_require_current()`, `_work_dir()`, `_ensure_dirs()`

## Adding a New pmos Subcommand

1. Add case branch in `scripts.pmos.exec`:
```nix
newcmd)
  cur=$(_require_current)
  pmbootstrap --work "$(_work_dir "$cur")" <pmbootstrap-action>
  ;;
```

2. Add to `help` case branch
3. Update `enterShell` if commonly used
4. Update README.md command reference table

## NixOS Requirement

Users must enable ARM emulation in their NixOS config:
```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
```
