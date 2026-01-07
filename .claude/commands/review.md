---
description: Perform a code review on recent changes
---

Review all changes in the current branch compared to main:

1. Run `git diff main...HEAD` to see all changes
2. Run `git log main..HEAD --oneline` to see commit history

Check each changed file for:

**Swift 6.0 Compliance:**
- Proper @MainActor annotations on UI code
- Actor-based services for shared state
- Sendable types for cross-actor boundaries
- No data races or concurrency warnings

**Code Quality:**
- No force unwraps (use guard/if-let)
- Comprehensive error handling
- Meaningful variable and function names
- Functions under 50 lines where possible

**Testing:**
- Test coverage for new code
- Tests follow "Real Over Mock" philosophy
- Descriptive test names: test<Feature>_<Scenario>_<Expected>

**iOS Standards:**
- Accessibility labels on all interactive elements
- LocalizedStringKey for user-facing text
- Adherence to docs/ios/IOS_STYLE_GUIDE.md

Provide feedback as:
- **Critical Issues**: Must fix before merge
- **Suggestions**: Nice to have improvements
- **Positive Notes**: Well-done aspects
