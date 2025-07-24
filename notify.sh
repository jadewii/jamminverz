#!/bin/bash

# Script to notify when coding is complete
# Run this script: bash notify.sh

# Using macOS 'say' command to speak the message
say "Hey! Something needs your attention. Your code is ready!"

# Also play a system sound
afplay /System/Library/Sounds/Glass.aiff

echo "✅ Notification sent!"