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

check_backup() {
  local target="$1"

  # nothing there or linked
  if [ ! -e "$target" ] || [ -L "$target" ]; then
    return 0
  fi

  if ! confirm "Existing path found at $target. Back it up?"; then
    echo "Aborting so nothing gets overwritten"
    exit 1
  fi 
  
  local backup="${target}.backup.$(date +%Y%m%d%H%H%S)"
  mv "$target" "$backup"
  echo "Backed up $target => $backup \n"
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

echo ""

# Check for existing home files
for entry in "$DOTFILES_DIR"/home/.[!.]*; do
  [ -e "$entry" ] || continue

  name="$(basename "$entry")"
  target="$HOME/$name"

  check_backup "$target"
done

# Check for existing .config files
for entry in "$DOTFILES_DIR"/xdg/*; do
  [ -e "$entry" ] || continue

  name="$(basename "$entry")"
  target="$HOME/.config/$name"

  check_backup "$target"
done

echo "Creating symlinks..."
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow home
stow --dir="$DOTFILES_DIR" --target="$HOME/.config" --restow xdg
echo "Created symlinks"
