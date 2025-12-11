#!/bin/bash
set -e
echo "🧪 Running quick tests..."
xcodebuild test \
  -scheme VoiceLearn \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:VoiceLearnTests/Unit \
  | xcbeautify
echo "✓ Quick tests passed"
