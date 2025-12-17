{ pkgs, ... }:

{
  # Environment variables
  env = {
    PMOS_DEVICES_DIR = "${toString ./.}/devices";
    PMOS_CURRENT_FILE = "${toString ./.}/.current-device";
    PMOS_OUT_DIR = "${toString ./.}/out";
    # Proxy configuration (uncomment if needed)
    # HTTP_PROXY = "http://127.0.0.1:3128";
    # HTTPS_PROXY = "http://127.0.0.1:3128";
  };

  # Dependencies
  packages = with pkgs; [
    pmbootstrap
    android-tools
    qemu
    fzf
    git
  ];

  # Show help on entering environment
  enterShell = ''
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           postmarketOS Builder Environment Ready              ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║  Common commands:                                             ║"
    echo "║    pmos new <device>   - Create device environment            ║"
    echo "║    pmos use [device]   - Switch device (fzf if no argument)   ║"
    echo "║    pmos init           - Initialize pmbootstrap               ║"
    echo "║    pmos build          - Build system image                   ║"
    echo "║    pmos flash          - Flash to device                      ║"
    echo "║    pmos help           - Show all commands                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Note: Ensure binfmt is enabled in NixOS:"
    echo "  boot.binfmt.emulatedSystems = [ \"aarch64-linux\" \"armv7l-linux\" ];"
    echo ""
  '';

  # pmos command implementation
  scripts.pmos.exec = ''
    set -e

    # Helper functions
    _get_current() {
      if [ -f "$PMOS_CURRENT_FILE" ]; then
        cat "$PMOS_CURRENT_FILE"
      fi
    }

    _require_current() {
      local cur=$(_get_current)
      if [ -z "$cur" ]; then
        echo "Error: No device selected. Run 'pmos use <device>' first" >&2
        exit 1
      fi
      echo "$cur"
    }

    _work_dir() {
      echo "$PMOS_DEVICES_DIR/$1"
    }

    _ensure_dirs() {
      mkdir -p "$PMOS_DEVICES_DIR"
      mkdir -p "$PMOS_OUT_DIR"
    }

    cmd="''${1:-help}"
    shift || true

    case "$cmd" in
      new)
        device="$1"
        if [ -z "$device" ]; then
          echo "Usage: pmos new <device>"
          echo "Example: pmos new pine64-pinephone"
          exit 1
        fi
        _ensure_dirs
        work_dir=$(_work_dir "$device")
        if [ -d "$work_dir" ]; then
          echo "Error: Device '$device' already exists"
          exit 1
        fi
        mkdir -p "$work_dir"
        echo "$device" > "$PMOS_CURRENT_FILE"
        echo "Created device environment: $device"
        echo "Work directory: $work_dir"
        echo "Switched to: $device"
        echo ""
        echo "Next step: Run 'pmos init' to initialize pmbootstrap"
        ;;

      use)
        _ensure_dirs
        device="$1"
        if [ -z "$device" ]; then
          # Use fzf for selection
          if [ ! -d "$PMOS_DEVICES_DIR" ] || [ -z "$(ls -A "$PMOS_DEVICES_DIR" 2>/dev/null)" ]; then
            echo "Error: No devices available. Run 'pmos new <device>' first"
            exit 1
          fi
          device=$(ls -1 "$PMOS_DEVICES_DIR" | fzf --prompt="Select device: " --height=10)
          if [ -z "$device" ]; then
            echo "Selection cancelled"
            exit 0
          fi
        fi
        work_dir=$(_work_dir "$device")
        if [ ! -d "$work_dir" ]; then
          echo "Error: Device '$device' does not exist"
          exit 1
        fi
        echo "$device" > "$PMOS_CURRENT_FILE"
        echo "Switched to: $device"
        ;;

      list)
        _ensure_dirs
        if [ ! -d "$PMOS_DEVICES_DIR" ] || [ -z "$(ls -A "$PMOS_DEVICES_DIR" 2>/dev/null)" ]; then
          echo "No devices"
          exit 0
        fi
        current=$(_get_current)
        echo "Devices:"
        for d in "$PMOS_DEVICES_DIR"/*/; do
          name=$(basename "$d")
          if [ "$name" = "$current" ]; then
            echo "  * $name (current)"
          else
            echo "    $name"
          fi
        done
        ;;

      current)
        cur=$(_get_current)
        if [ -z "$cur" ]; then
          echo "No device selected"
        else
          echo "$cur"
        fi
        ;;

      rm)
        device="$1"
        if [ -z "$device" ]; then
          echo "Usage: pmos rm <device>"
          exit 1
        fi
        work_dir=$(_work_dir "$device")
        if [ ! -d "$work_dir" ]; then
          echo "Error: Device '$device' does not exist"
          exit 1
        fi
        read -p "Are you sure you want to delete device '$device'? [y/N] " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
          rm -rf "$work_dir"
          current=$(_get_current)
          if [ "$current" = "$device" ]; then
            rm -f "$PMOS_CURRENT_FILE"
          fi
          echo "Deleted: $device"
        else
          echo "Cancelled"
        fi
        ;;

      init)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        echo "Initializing device: $cur"
        pmbootstrap --work "$work_dir" init
        ;;

      build)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        echo "Building device: $cur"
        pmbootstrap --work "$work_dir" install
        ;;

      flash)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        echo "Flashing device: $cur"
        pmbootstrap --work "$work_dir" flasher flash_rootfs
        pmbootstrap --work "$work_dir" flasher flash_kernel
        ;;

      export)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        out_dir="$PMOS_OUT_DIR/$cur"
        mkdir -p "$out_dir"
        echo "Exporting image: $cur -> $out_dir"
        pmbootstrap --work "$work_dir" export "$out_dir"
        echo "Image exported to: $out_dir"
        ;;

      shell)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        echo "Entering chroot: $cur"
        pmbootstrap --work "$work_dir" chroot
        ;;

      status)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        echo "Device status: $cur"
        echo "Work directory: $work_dir"
        echo ""
        pmbootstrap --work "$work_dir" config
        ;;

      log)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        pmbootstrap --work "$work_dir" log
        ;;

      clean)
        cur=$(_require_current)
        work_dir=$(_work_dir "$cur")
        if [ "$1" = "--all" ]; then
          read -p "Are you sure you want to clean all caches? [y/N] " confirm
          if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            pmbootstrap --work "$work_dir" zap -p -hc -m -o
            echo "All caches cleaned"
          else
            echo "Cancelled"
          fi
        else
          read -p "Are you sure you want to clean build cache? [y/N] " confirm
          if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            pmbootstrap --work "$work_dir" zap
            echo "Build cache cleaned"
          else
            echo "Cancelled"
          fi
        fi
        ;;

      help|--help|-h)
        echo "pmos - postmarketOS Build Environment Management Tool"
        echo ""
        echo "Device Management:"
        echo "  pmos new <device>     Create a new device environment"
        echo "  pmos use [device]     Switch device (uses fzf without argument)"
        echo "  pmos list             List all devices"
        echo "  pmos current          Show current device"
        echo "  pmos rm <device>      Remove device environment"
        echo ""
        echo "Build Operations:"
        echo "  pmos init             Initialize pmbootstrap (interactive config)"
        echo "  pmos build            Build system image"
        echo "  pmos flash            Flash to device"
        echo "  pmos export           Export image to out/ directory"
        echo ""
        echo "Debug Tools:"
        echo "  pmos shell            Enter device chroot environment"
        echo "  pmos status           View current configuration"
        echo "  pmos log              View build logs"
        echo ""
        echo "Maintenance:"
        echo "  pmos clean            Clean build cache"
        echo "  pmos clean --all      Clean all caches (including package cache)"
        echo ""
        echo "  pmos help             Show this help message"
        ;;

      *)
        echo "Unknown command: $cmd"
        echo "Run 'pmos help' for available commands"
        exit 1
        ;;
    esac
  '';
}
