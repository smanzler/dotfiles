#!/usr/bin/env bash
set -euo pipefail

ASSUME_YES=false

for arg in "$@"; do
  case $arg in
    --yes|-y) ASSUME_YES=true ;;
  esac
done

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

INFO="${BLUE}[INFO]${RESET}"
WARN="${YELLOW}[WARN]${RESET}"
Q="${GREEN}[?]${RESET}"

printf "$INFO Starting bootstrap at ${BLUE}${DOTFILES_DIR}${RESET}\n"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"

  if [ "$ASSUME_YES" = true ]; then
    printf "$Q $prompt (Y/n): yes (auto)\n"
    return 0
  fi

  while true; do
    printf "$Q $prompt (Y/n): "
    read -r answer
    answer=${answer:-Y}

    case "$answer" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) printf "$WARN Please enter y or n\n" ;;
    esac
  done
}

check_backup() {
  local target="$1"

  # nothing there or linked
  if [ ! -e "$target" ] || [ -L "$target" ]; then
    return 0
  fi

  if ! confirm "$WARN Existing path found at $target. Back it up?"; then
    printf "Aborting so nothing gets overwritten"
    exit 1
  fi 
  
  local backup="${target}.backup.$(date +%Y%m%d%H%H%S)"
  mv "$target" "$backup"
  printf "$INFO Backed up $target => $backup \n"
}
    

# Install homebrew
if ! command_exists brew; then
  if ! confirm "Would you like to install homebrew?"; then
    exit 1
  fi

  printf "$INFO Installing homebrew...\n"

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! command_exists brew; then
    printf "Unable to install homebrew"
    exit 1
  fi

  printf "$INFO Installed homebrew successfully\n"
fi

# Install Brewfile packages
if confirm "Would you like to install packages from Brewfile?"; then
  printf "$INFO Installing packages...\n"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
  printf "$INFO Installed packages\n"
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

printf "$INFO Creating symlinks...\n"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow home
stow --dir="$DOTFILES_DIR" --target="$HOME/.config" --restow xdg
printf "$INFO Created symlinks\n"
