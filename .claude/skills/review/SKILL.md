---
name: review
description: Perform a code review on recent changes
---

# /review - Code Review Workflow

## Purpose

Performs a comprehensive code review of changes in the current branch compared to main. This skill ensures code quality, Swift 6.0 compliance, accessibility standards, and testing requirements are met.

## Usage

```
/review              # Review all changes vs main branch
/review staged       # Review only staged changes
/review <file>       # Review specific file
/review --quick      # Quick review (skip detailed checks)
```

## Workflow

### 1. Identify Changes
```bash
git diff main...HEAD           # All changes vs main
git log main..HEAD --oneline   # Commit history
git diff --cached              # Staged changes only
```

### 2. Review Each Changed File

For each file, check the following categories:

#### Swift 6.0 Concurrency Compliance
- `@MainActor` annotations on UI code
- Actor-based services for shared state
- `Sendable` types for cross-actor boundaries
- No data races or concurrency warnings
- Proper async/await usage

#### Code Quality
- No force unwraps (`!`) - use `guard`/`if-let`
- Comprehensive error handling
- Meaningful variable and function names
- Functions under 50 lines where possible
- No magic numbers or hardcoded strings
- Proper use of access control (`private`, `internal`, `public`)

#### Testing Requirements
- Test coverage for new code
- Tests follow "Real Over Mock" philosophy
- Descriptive test names: `test<Feature>_<Scenario>_<Expected>`
- Edge cases covered
- Integration tests for complex flows

#### iOS Standards
- Accessibility labels on all interactive elements
- `LocalizedStringKey` for user-facing text
- Adherence to `docs/ios/IOS_STYLE_GUIDE.md`
- Proper memory management (no retain cycles)
- SwiftUI best practices

### 3. Generate Report

Provide feedback in three categories:

**Critical Issues** - Must fix before merge
- Security vulnerabilities
- Data races
- Memory leaks
- Missing error handling
- Broken functionality

**Suggestions** - Nice to have improvements
- Code organization
- Naming improvements
- Additional test coverage
- Performance optimizations

**Positive Notes** - Well-done aspects
- Good patterns used
- Clean code
- Comprehensive tests
- Clear documentation

## Success Criteria

- All critical issues identified
- Clear, actionable feedback provided
- Suggestions are constructive
- Positive aspects acknowledged

## Examples

**Standard review:**
```
User: /review
Claude: Reviewing changes in current branch vs main...

Files changed: 5
Commits: 3

## File Reviews

### UnaMentis/Services/AudioEngine.swift
**Critical Issues:**
- Line 142: Force unwrap on optional `audioSession!` - use guard let
- Line 198: Missing @MainActor on UI callback

**Suggestions:**
- Line 67-89: Consider extracting audio configuration to separate method

### UnaMentis/Views/SessionView.swift
**Critical Issues:** None

**Suggestions:**
- Line 34: Add accessibility label to mic button

**Positive Notes:**
- Clean separation of view and view model
- Good use of @StateObject

### UnaMentisTests/AudioEngineTests.swift
**Positive Notes:**
- Comprehensive test coverage
- Good use of descriptive test names
- Edge cases well covered

## Summary
- Critical Issues: 2 (must fix)
- Suggestions: 2
- Files approved: 3/5

Fix the critical issues before merging.
```

**Quick review:**
```
User: /review --quick
Claude: Quick review of changes...

Files changed: 5
Critical issues found: 2

1. AudioEngine.swift:142 - Force unwrap
2. AudioEngine.swift:198 - Missing @MainActor

Run `/review` for detailed analysis.
```

**Review specific file:**
```
User: /review UnaMentis/Services/LLMService.swift
Claude: Reviewing LLMService.swift...

**Swift 6.0 Compliance:** PASS
- Actor-based service design
- Proper Sendable conformance
- Clean async/await usage

**Code Quality:** PASS
- Good error handling
- Clear function names
- Reasonable function lengths

**Testing:** NEEDS ATTENTION
- New `streamResponse` method lacks tests
- Suggest adding: testStreamResponse_success, testStreamResponse_timeout

**Overall:** Approved with minor suggestion for test coverage.
```

## Integration

This skill replaces `.claude/commands/review.md` and should be run:
- Before creating a pull request
- During code review sessions
- When reviewing someone else's changes
