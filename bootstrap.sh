#!/usr/bin/env bash
set -euo pipefail

ASSUME_YES=false

for arg in "$@"; do
  case $arg in
    --yes|-y) ASSUME_YES=true ;;
  esac
done

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "Starting bootstrap at \033[34m$DOTFILES_DIR\033[0m"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"

  if [ "$ASSUME_YES" = true ]; then
    echo "$prompt (Y/n): yes (auto)"
    return 0
  fi

  while true; do
    read -p "$prompt (Y/n): " answer
    answer=${answer:-Y}

    case "$answer" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) echo "Please enter y or n" ;;
    esac
  done
}

confirm "testing"
echo $?

echo -e "\033[32mDone\033[0m"
