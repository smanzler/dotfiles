#!/usr/bin/env bash

pkill -USR1 -f gpu-screen-recorder

if [ $? -eq 0 ]; then

  pw-play /usr/share/sounds/freedesktop/stereo/message-new-instant.oga &

  # notify-send \
  #     -a "Clip Recorder" \
  #     "Clip Saved" \
  #     "Replay buffer saved successfully."

else
  pw-play /usr/share/sounds/freedesktop/stereo/dialog-error.oga &

  notify-send \
      -u critical \
      -a "Clip Recorder" \
      "Clip Failed" \
      "Failed to save replay buffer."

fi
