#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/gsr-recording"

if [[ -f "$STATE_FILE" ]]; then
    echo '{"text":"⏺ REC","class":"recording"}'
else
    echo '{"text":"● idle","class":"idle"}'
fi
