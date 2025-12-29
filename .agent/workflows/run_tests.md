---
description: Run UnaMentis unit tests with turbo mode
---

# Run Tests (Turbo)

This workflow runs the unit tests for the UnaMentis project associated with the Curriculum feature.

// turbo-all
Run the tests using xcodebuild:
```bash
xcodebuild clean test -scheme UnaMentis -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:UnaMentisTests/CurriculumEngineTests -only-testing:UnaMentisTests/DocumentProcessorTests -only-testing:UnaMentisTests/ProgressTrackerTests
```
