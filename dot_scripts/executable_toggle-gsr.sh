#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/gsr-recording"
PID_FILE="$HOME/.cache/gsr.pid"

mkdir -p "$HOME/.cache"

if [[ -f "$STATE_FILE" ]]; then
    # STOP
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi

    rm -f "$STATE_FILE"
    notify-send "Recording stopped"
    exit 0
fi

# START
gpu-screen-recorder -w screen \
  -f 60 \
  -r 20 \
  -a default_output \
  -a default_input \
  -c mp4 \
  -o "$HOME/Clips" \
  >/dev/null 2>&1 &


PID=$!
disown

echo "$PID" > "$PID_FILE"
touch "$STATE_FILE"

notify-send "Recording started"
