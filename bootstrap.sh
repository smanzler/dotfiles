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

# Install homebrew
if ! command_exists brew; then
  if ! confirm "Would you like to install homebrew?"; then
    exit 1
  fi

  echo "Installing homebrew..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! command_exists brew; then
    echo "Unable to install homebrew"
    exit 1
  fi

  echo "Installed homebrew successfully"
fi

# Install Brewfile packages
if confirm "Would you like to install packages from Brewfile?"; then
  echo "Installing packages..."
  brew bundle --file="$DOTFILES_DIR/Brewfile"
  echo "Installed packages"
fi

# Check if stow is available
if ! command_exists stow; then
  # Exit for now
  exit 1
fi

echo "Creating symlinks..."
if ! stow --dir="$DOTFILES_DIR" --target="$HOME" --restow . >/dev/null; then
  exit 1
fi
echo "Created symlinks"

echo -e "\033[32mDone\033[0m"
