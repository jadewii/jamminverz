#!/bin/bash
# Kill any running instances of JAMVERZ app

echo "Killing any running JAMVERZ instances..."

# Kill by bundle identifier
pkill -f "com.jadewii.JAMVERZ" || true

# Kill by app name
pkill -f "JAMVERZ" || true

# Shutdown all simulators (optional, uncomment if needed)
# xcrun simctl shutdown all 2>/dev/null || true

echo "Done! You can now run the app."