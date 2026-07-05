#!/usr/bin/env bash

tmp=$(mktemp)

printf '%s\n' "$HOME"/Clips/* | sort -r > "$tmp"

mpv --playlist="$tmp"

rm -f "$tmp"
