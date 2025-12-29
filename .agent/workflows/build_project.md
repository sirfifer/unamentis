---
description: Build the UnaMentis project (compilation check)
---

# Build Project (Turbo)

This workflow builds the UnaMentis project to verify compilation.

// turbo-all
1.  Build the project using xcodebuild:
    ```bash
    xcodebuild build -scheme UnaMentis -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
    ```
