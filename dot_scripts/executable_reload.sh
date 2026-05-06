#!/usr/bin/env bash

# chezmoi
chezmoi apply --force

# waybar
killall waybar
nohup waybar >/dev/null 2>&1 &

# hyprpaper
killall hyprpaper
nohup hyprpaper >/dev/null 2>&1 &

# ghostty
systemctl reload --user app-com.mitchellh.ghostty.service
