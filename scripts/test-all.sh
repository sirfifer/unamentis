#!/bin/bash
set -e
echo "🧪 Running full test suite..."
xcodebuild test \
  -scheme VoiceLearn \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -enableCodeCoverage YES \
  | xcbeautify
echo "✓ All tests passed"
