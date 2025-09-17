#!/bin/bash

# Script to add microphone permission to Xcode project
# This adds NSMicrophoneUsageDescription to the project's Info.plist

echo "Adding microphone permission to Xcode project..."

# The permission needs to be added through Xcode's project settings
# Since we can't directly modify the embedded Info.plist, we'll provide instructions

echo "To add microphone permission:"
echo "1. Open the project in Xcode"
echo "2. Select the project in the navigator"
echo "3. Select the 'chorepal prototype' target"
echo "4. Go to the 'Info' tab"
echo "5. Add a new key: 'Privacy - Microphone Usage Description'"
echo "6. Set the value to: 'This app uses the microphone to record voice commands for creating chores and tasks. Your voice is processed to understand chore assignments and converted to text for task creation.'"
echo ""
echo "Alternatively, you can add this to the project's Info.plist:"
echo "<key>NSMicrophoneUsageDescription</key>"
echo "<string>This app uses the microphone to record voice commands for creating chores and tasks. Your voice is processed to understand chore assignments and converted to text for task creation.</string>"

