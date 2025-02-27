#!/usr/bin/env bash
#
# install.sh: Installs UHPC-Tools scripts either to user-local (~/.local/bin) 
#             or system-wide (/usr/local/bin).
#
# Usage:
#   ./install.sh --user   # Install to ~/.local/bin
#   ./install.sh --system # Install to /usr/local/bin
#

set -o errexit
set -o nounset

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"  # Where scripts are stored (uhpc-list, uhpc-multipush, etc.)

install_user() {
  local dest="$HOME/.local/bin"
  mkdir -p "$dest"
  for f in "$BIN_DIR"/*; do
    cp -v "$f" "$dest/"
    chmod +x "$dest/$(basename "$f")"
  done
  echo "Installed UHPC-Tools to $dest"
  echo "Make sure $dest is on your PATH."
}

install_system() {
  local dest="/usr/local/bin"
  sudo mkdir -p "$dest"
  for f in "$BIN_DIR"/*; do
    sudo cp -v "$f" "$dest/"
    sudo chmod +x "$dest/$(basename "$f")"
  done
  echo "Installed UHPC-Tools to $dest"
}

main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 --user|--system"
    exit 1
  fi

  case "$1" in
    --user)
      install_user
      ;;
    --system)
      install_system
      ;;
    *)
      echo "Invalid argument: $1"
      echo "Usage: $0 --user|--system"
      exit 1
      ;;
  esac
}

main "$@"