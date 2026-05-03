#!/usr/bin/env bash

if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh missing, installing first..."
  exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
